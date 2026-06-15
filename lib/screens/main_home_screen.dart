import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../presentation/screens/battle_screen.dart';
import '../domain/battle_engine.dart';
import '../domain/models/character.dart';
import '../domain/models/equipment.dart';
import '../domain/models/relic.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 1; // 기본적으로 '메인 홈' 선택
  late AudioPlayer _audioPlayer;
  String _nickname = 'Default_User'; // 닉네임 상태 변수
  int _gold = 0; // 보유 골드
  bool _isFirstEntry = false; // 처음 진입 여부 확인

  // 장비 관련 상태
  Map<String, int> _inventory = {}; // { 'sword_c1': 5, ... }
  Map<String, String?> _equippedItems = {
    'sword': null,
    'shield': null,
    'helmet': null,
  };

  // 유물 관련 상태
  Map<String, int> _relicInventory = {}; // { 'relic_atk': 3, ... }
  Map<String, int> _relicLevels = {};    // { 'relic_atk': 1, ... }

  List<String> _unlockedStages = ['1-1'];
  String _selectedStage = '1-1';
  bool _isInitialLoad = true; // 처음 데이터 로드 여부

  // BGM 설정 상태
  double _bgmVolume = 0.5;
  bool _isBgmEnabled = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadSettings();
    _checkUserData();
  }

  // 설정 로드
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bgmVolume = prefs.getDouble('bgmVolume') ?? 0.5;
      _isBgmEnabled = prefs.getBool('isBgmEnabled') ?? true;
    });
    _playBgm();
  }

  // 설정 저장
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bgmVolume', _bgmVolume);
    await prefs.setBool('isBgmEnabled', _isBgmEnabled);
  }

  // Firestore에서 유저 데이터 확인
  Future<void> _checkUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            if (data['nickname'] != null) _nickname = data['nickname'];
            if (data['gold'] != null) _gold = data['gold'];
            
            // 장착 정보 로드
            if (data['inventory'] != null) {
              _inventory = Map<String, int>.from(data['inventory']);
            }
            if (data['equipped'] != null) {
              _equippedItems = Map<String, String?>.from(data['equipped']);
            }

            // 유물 정보 로드
            if (data['relicInventory'] != null) {
              _relicInventory = Map<String, int>.from(data['relicInventory']);
            }
            if (data['relicLevels'] != null) {
              _relicLevels = Map<String, int>.from(data['relicLevels']);
            }

            // 해금된 스테이지 목록 가져오기 (항상 1-1은 포함)
            if (data['unlockedStages'] != null) {
              final list = List<String>.from(data['unlockedStages']);
              if (!list.contains('1-1')) list.add('1-1');
              _unlockedStages = list;
              
              // 데이터 로드 시 한 번만 초기 스테이지 설정 (이미 선택된 스테이지가 있다면 유지)
              if (_isInitialLoad) {
                if (data['lastClearedStage'] != null && _unlockedStages.contains(data['lastClearedStage'])) {
                  _selectedStage = data['lastClearedStage'];
                } else if (_unlockedStages.isNotEmpty) {
                  _selectedStage = _unlockedStages.last;
                }
                _isInitialLoad = false;
              }
            }
          });
        }
      } else {
        // 데이터가 없는 경우 (첫 진입)
        setState(() {
          _isFirstEntry = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showNicknameDialog();
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  // Firestore에 닉네임 저장
  Future<void> _saveNickname(String newNickname) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'nickname': newNickname,
        'createdAt': FieldValue.serverTimestamp(),
        'unlockedStages': ['1-1'], // 초기 스테이지 해금
        'gold': 0,
      }, SetOptions(merge: true));
      
      setState(() {
        _nickname = newNickname;
      });
    } catch (e) {
      debugPrint('Error saving nickname: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임 저장에 실패했습니다.')),
        );
      }
    }
  }

  void _showNicknameDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.brown, width: 4),
          ),
          title: const Column(
            children: [
              Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 40),
              SizedBox(height: 10),
              Text(
                '새로운 용사의 탄생!',
                style: TextStyle(
                  color: Colors.brown,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '사용하실 닉네임을 입력해 주세요.',
                style: TextStyle(color: Colors.brown, fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '닉네임 (최대 10자)',
                  filled: true,
                  fillColor: Colors.brown.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
                  ),
                ),
                textAlign: TextAlign.center,
                maxLength: 10,
              ),
            ],
          ),
          actions: [
            Center(
              child: GestureDetector(
                onTap: () async {
                  final enteredNickname = controller.text.trim();
                  if (enteredNickname.isNotEmpty) {
                    await _saveNickname(enteredNickname);
                    if (mounted) Navigator.of(context).pop();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.orangeAccent, Colors.deepOrange],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orangeAccent.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    '확 인',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
  }

  void _showSummonDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.purpleAccent, width: 2),
          ),
          title: const Text('소환 상점', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummonOption('장비 1회 소환', '300 골드', () => _handleSummon('equip', 1, 300)),
              const SizedBox(height: 12),
              _buildSummonOption('장비 5회 소환', '1000 골드', () => _handleSummon('equip', 5, 1000)),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 20),
              _buildSummonOption('유물 1회 소환', '1000 골드', () => _handleSummon('relic', 1, 1000), isRelic: true),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(color: Colors.white60)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummonOption(String title, String cost, VoidCallback onTap, {bool isRelic = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRelic 
                ? [Colors.orangeAccent.withOpacity(0.2), Colors.deepOrange.withOpacity(0.2)]
                : [Colors.blueAccent.withOpacity(0.2), Colors.indigo.withOpacity(0.2)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isRelic ? Colors.orangeAccent.withOpacity(0.5) : Colors.blueAccent.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.yellowAccent, size: 18),
                const SizedBox(width: 4),
                Text(cost, style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSummon(String type, int count, int cost) async {
    if (_gold < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('골드가 부족합니다!')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    List<String> rolledIds = [];
    if (type == 'equip') {
      for (int i = 0; i < count; i++) {
        rolledIds.add(Equipment.rollEquipmentId());
      }
    } else {
      // 유물 소환
      for (int i = 0; i < count; i++) {
        rolledIds.add(Relic.rollRelicId());
      }
    }

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      Map<String, dynamic> updates = {};
      updates['gold'] = FieldValue.increment(-cost);

      if (type == 'equip') {
        for (var id in rolledIds) {
          updates['inventory.$id'] = FieldValue.increment(1);
        }
      } else {
        for (var id in rolledIds) {
          updates['relicInventory.$id'] = FieldValue.increment(1);
        }
      }

      await userRef.update(updates);
      
      setState(() {
        _gold -= cost;
        if (type == 'equip') {
          for (var id in rolledIds) {
            _inventory[id] = (_inventory[id] ?? 0) + 1;
          }
        } else {
          for (var id in rolledIds) {
            _relicInventory[id] = (_relicInventory[id] ?? 0) + 1;
          }
        }
      });

      if (mounted) {
        Navigator.pop(context); // 상점 닫기
        _showSummonResult(rolledIds, isRelic: type == 'relic');
      }
    } catch (e) {
      debugPrint('Error during summon: $e');
    }
  }

  void _showSummonResult(List<String> itemIds, {bool isRelic = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isRelic ? Colors.orangeAccent : Colors.purpleAccent, width: 2),
          ),
          title: Center(
            child: Text(
              isRelic ? '유물 소환 성공!' : '장비 소환 성공!',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: itemIds.length,
              itemBuilder: (context, index) {
                final id = itemIds[index];
                
                if (isRelic) {
                  final relic = Relic.fromId(id);
                  if (relic == null) return const SizedBox();
                  return ListTile(
                    leading: _buildRelicGradeIcon(relic.grade),
                    title: Text(relic.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(relic.description, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  );
                }

                final equip = Equipment.fromId(id);
                String typeName = '장비';
                if (equip.type == EquipmentType.sword) typeName = '무기';
                else if (equip.type == EquipmentType.shield) typeName = '방패';
                else if (equip.type == EquipmentType.helmet) typeName = '모자';

                return ListTile(
                  leading: _buildGradeIcon(equip.grade),
                  title: Row(
                    children: [
                      Text(equip.name, style: const TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeName,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _getStatDescription(equip),
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                );
              },
            ),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRelic ? Colors.orangeAccent : Colors.purpleAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                ),
                child: const Text('확인', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildRelicGradeIcon(RelicGrade grade) {
    Color color = Colors.grey;
    String label = 'C';
    if (grade == RelicGrade.rare) { color = Colors.blueAccent; label = 'R'; }
    else if (grade == RelicGrade.epic) { color = Colors.orangeAccent; label = 'E'; }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildGradeIcon(String grade) {
    Color color = Colors.grey;
    if (grade.startsWith('B')) color = Colors.blueAccent;
    else if (grade.startsWith('A')) color = Colors.purpleAccent;
    else if (grade.startsWith('S')) color = Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        grade,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  String _getStatDescription(Equipment equip) {
    if (equip.type == EquipmentType.sword) return '공격력 +${equip.statValue.toInt()}';
    if (equip.type == EquipmentType.shield) return '방어력 +${equip.statValue.toInt()}';
    return '최대 체력 +${equip.statValue.toInt()}';
  }

  void _showStageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('스테이지 선택', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStageTile('1-1', '신비의 숲'),
              const SizedBox(height: 10),
              _buildStageTile('1-2', '푸른 숲의 깊은 곳'),
              const SizedBox(height: 10),
              _buildStageTile('1-3', '안개 낀 고대의 유적'),
              const SizedBox(height: 10),
              _buildStageTile('2-1', '어두운 해골 던전'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStageTile(String id, String name) {
    bool isUnlocked = _unlockedStages.contains(id);
    bool isSelected = _selectedStage == id;

    return GestureDetector(
      onTap: isUnlocked ? () {
        setState(() => _selectedStage = id);
        Navigator.pop(context);
      } : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orangeAccent.withOpacity(0.2) : Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.orangeAccent : (isUnlocked ? Colors.white30 : Colors.white10),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUnlocked ? Icons.lock_open : Icons.lock,
              color: isUnlocked ? Colors.orangeAccent : Colors.white24,
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STAGE $id',
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    color: isUnlocked ? Colors.white70 : Colors.white10,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  DungeonRun _getDungeonRun(String stageId) {
    if (stageId == '2-1') return DungeonRun.stage2_1();
    if (stageId == '1-3') return DungeonRun.stage1_3();
    if (stageId == '1-2') return DungeonRun.stage1_2();
    return DungeonRun.stage1_1();
  }

  String _getStageName(String stageId) {
    if (stageId == '2-1') return 'STAGE 2-1: 어두운 해골 던전';
    if (stageId == '1-3') return 'STAGE 1-3: 정령이 잠든 숲의 끝';
    if (stageId == '1-2') return 'STAGE 1-2: 푸른 숲의 깊은 곳';
    return 'STAGE 1-1: 신비의 숲';
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: const BorderSide(color: Colors.brown, width: 4),
              ),
              title: const Row(
                children: [
                  Icon(Icons.settings, color: Colors.brown),
                  SizedBox(width: 10),
                  Text(
                    '설 정',
                    style: TextStyle(
                      color: Colors.brown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // BGM On/Off
                  SwitchListTile(
                    title: const Text('배경음악', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                    value: _isBgmEnabled,
                    activeColor: Colors.orangeAccent,
                    onChanged: (bool value) {
                      setDialogState(() {
                        _isBgmEnabled = value;
                      });
                      setState(() {
                        _isBgmEnabled = value;
                      });
                      _updateBgmSettings();
                      _saveSettings();
                    },
                  ),
                  // Volume Slider
                  if (_isBgmEnabled) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.volume_down, color: Colors.brown, size: 20),
                          Spacer(),
                          Icon(Icons.volume_up, color: Colors.brown, size: 20),
                        ],
                      ),
                    ),
                    Slider(
                      value: _bgmVolume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: Colors.orangeAccent,
                      inactiveColor: Colors.brown.withOpacity(0.2),
                      onChanged: (double value) {
                        setDialogState(() {
                          _bgmVolume = value;
                        });
                        setState(() {
                          _bgmVolume = value;
                        });
                        _updateBgmSettings();
                        _saveSettings();
                      },
                    ),
                  ],
                  const Divider(color: Colors.brown),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(
                      '로그아웃',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _stopBgm();
                      await FirebaseAuth.instance.signOut();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const Divider(color: Colors.brown),
                  ListTile(
                    leading: const Icon(Icons.close, color: Colors.grey),
                    title: const Text('닫기'),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _playBgm() async {
    if (!_isBgmEnabled) {
      await _audioPlayer.stop();
      return;
    }
    
    try {
      // 이미 재생 중이면 볼륨만 조절하고 리턴
      if (_audioPlayer.state == PlayerState.playing) {
        await _audioPlayer.setVolume(_bgmVolume);
        return;
      }

      // 정지 상태 등에서 재생 시 설정 재적용
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_bgmVolume);
      await _audioPlayer.play(AssetSource('bgm_main.mp3'));
    } catch (e) {
      debugPrint('Home BGM Error: $e');
    }
  }

  Future<void> _updateBgmSettings() async {
    if (!_isBgmEnabled) {
      // 확실하게 정지 시킴
      await _audioPlayer.stop();
    } else {
      await _playBgm();
    }
  }

  Future<void> _stopBgm() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // 화면을 나갈 때 리소스 해제
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildRelicTab() {
    final relics = Relic.allRelics;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('보유 유물', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                _buildGoldDisplay(),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 1.2,
              ),
              itemCount: relics.length,
              itemBuilder: (context, index) {
                final relic = relics[index];
                final level = _relicLevels[relic.id] ?? 1;
                final count = _relicInventory[relic.id] ?? 0;
                final nextLevel = level + 1;
                final requiredCount = Relic.getRequiredCountForLevel(nextLevel);
                final canUpgrade = count >= requiredCount && level < 4;

                return GestureDetector(
                  onTap: () => _showRelicDetail(relic),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _getRelicGradeColor(relic.grade),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getRelicGradeColor(relic.grade).withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Lv.$level',
                              style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold),
                            ),
                            if (canUpgrade)
                              const Icon(Icons.arrow_circle_up, color: Colors.greenAccent, size: 20),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          relic.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Text(
                          '보유: $count / $requiredCount',
                          style: TextStyle(
                            color: canUpgrade ? Colors.greenAccent : Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: (count / requiredCount).clamp(0.0, 1.0),
                            backgroundColor: Colors.white10,
                            valueColor: AlwaysStoppedAnimation<Color>(canUpgrade ? Colors.greenAccent : Colors.orangeAccent),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 130),
        ],
      ),
    );
  }

  Color _getRelicGradeColor(RelicGrade grade) {
    switch (grade) {
      case RelicGrade.common: return Colors.grey;
      case RelicGrade.rare: return Colors.blueAccent;
      case RelicGrade.epic: return Colors.orangeAccent;
    }
  }

  void _showRelicDetail(Relic relic) {
    final level = _relicLevels[relic.id] ?? 1;
    final count = _relicInventory[relic.id] ?? 0;
    final nextLevel = level + 1;
    final requiredCount = Relic.getRequiredCountForLevel(nextLevel);
    final canUpgrade = count >= requiredCount && level < 4;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _getRelicGradeColor(relic.grade), width: 2),
          ),
          title: Center(
            child: Text(relic.name, style: TextStyle(color: _getRelicGradeColor(relic.grade), fontWeight: FontWeight.bold)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '레벨 $level',
                style: const TextStyle(color: Colors.yellowAccent, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                relic.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '현재 효과: ${_getRelicValueDescription(relic, level)}',
                      style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                    ),
                    if (level < 4) ...[
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
                      Text(
                        '다음 효과: ${_getRelicValueDescription(relic, nextLevel)}',
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('보유 수량: $count / $requiredCount', style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: canUpgrade ? () async {
                  await _handleRelicLevelUp(relic);
                  if (mounted) Navigator.pop(context);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('레벨 업', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRelicValueDescription(Relic relic, int level) {
    final val = relic.getValue(level);
    switch (relic.id) {
      case 'relic_atk': return '공격력 +${val.toInt()}';
      case 'relic_def': return '방어력 +${val.toInt()}';
      case 'relic_hp': return '체력 +${val.toInt()}';
      case 'relic_crit_chance': return '치명타 확률 +${(val * 100).toInt()}%';
      case 'relic_crit_mult': return '치명타 배수 +${(val * 100).toInt()}%';
      case 'relic_atk_speed': return '공격 속도 +${(val * 100).toInt()}%';
      case 'relic_reroll': return '리롤 횟수 +${val.toInt()}회';
      case 'relic_stun_dmg': return '기절 적 추가 피해 +${(val * 100).toInt()}%';
      case 'relic_extra_gold': return '클리어 골드 +${val.toInt()}';
      case 'relic_start_card': return '시작 카드 선택 +${val.toInt()}개';
      default: return val.toString();
    }
  }

  Future<void> _handleRelicLevelUp(Relic relic) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final level = _relicLevels[relic.id] ?? 1;
    final nextLevel = level + 1;
    final requiredCount = Relic.getRequiredCountForLevel(nextLevel);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      await userRef.update({
        'relicInventory.${relic.id}': FieldValue.increment(-requiredCount),
        'relicLevels.${relic.id}': nextLevel,
      });
      
      setState(() {
        _relicInventory[relic.id] = (_relicInventory[relic.id] ?? 0) - requiredCount;
        _relicLevels[relic.id] = nextLevel;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${relic.name}이(가) Lv.$nextLevel로 업그레이드되었습니다!')));
      }
    } catch (e) {
      debugPrint('Error upgrading relic: $e');
    }
  }

  Widget _buildNavItem(int index, String iconPath) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Image.asset(
        iconPath,
        width: 60,
        height: 60,
        // 선택되지 않은 아이콘도 투명도 없이 다 보이게 함
        color: isSelected ? null : Colors.white.withOpacity(0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 공통 배경 이미지
          Positioned.fill(
            child: Image.asset(
              _selectedStage == '2-1' ? 'assets/dungeon.png' : 'assets/forest_.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. 탭별 컨텐츠
          _buildBody(),
          
          // 3. 커스텀 하단 네비게이션 바
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 130,
              padding: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/tab_bar.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(0, 'assets/relic_icon.png'),
                  _buildNavItem(1, 'assets/home_icon.png'),
                  _buildNavItem(2, 'assets/chast_icon.png'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildRelicTab();
      case 2:
        return _buildEquipmentTab();
      case 1:
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return Stack(
      children: [
        // 스테이지 보스 이미지 (중앙 배경)
        Center(
          child: Image.asset(
            _selectedStage == '2-1' ? 'assets/skel_boss.png' :
            _selectedStage == '1-3' ? 'assets/slime_boss2.png' : 'assets/slime_boss.png',
            width: MediaQuery.of(context).size.width * 0.7,
            fit: BoxFit.contain,
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const Spacer(),
              _buildStageAndStartArea(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 좌측 상단: 프로필 및 소환 버튼
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // 소환 버튼
              GestureDetector(
                onTap: _showSummonDialog,
                child: Image.asset('assets/summon_icon.png', width: 80, height: 80),
              ),
            ],
          ),
          // 중앙/우측: 골드 및 설정
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGoldDisplay(),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: _showSettingsDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoldDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.yellowAccent.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.monetization_on, color: Colors.yellowAccent, size: 20),
          const SizedBox(width: 6),
          Text(
            _gold.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageAndStartArea() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _showStageSelectionDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.brown[800]!.withOpacity(0.9), Colors.brown[900]!.withOpacity(0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.orangeAccent.withOpacity(0.5), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    _getStageName(_selectedStage),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              await _stopBgm();
              if (!mounted) return;
              
              // 장착된 장비 및 보유 유물 능력치를 적용한 플레이어 생성
              final player = Character.defaultPlayer();
              _applyPassiveBonuses(player);

              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BattleScreen(
                    engine: BattleEngine(
                      player: player,
                      run: _getDungeonRun(_selectedStage),
                    ),
                  ),
                ),
              );
              _checkUserData();
              if (mounted) _playBgm();
            },
            child: Image.asset(
              'assets/start_button.png',
              width: MediaQuery.of(context).size.width * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  void _applyPassiveBonuses(Character player) {
    // 1. 장비 능력치 적용
    for (var entry in _equippedItems.entries) {
      if (entry.value != null) {
        final equip = Equipment.fromId(entry.value!);
        if (equip.type == EquipmentType.sword) {
          player.baseAttack += equip.statValue;
        } else if (equip.type == EquipmentType.shield) {
          player.baseDefense += equip.statValue;
        } else if (equip.type == EquipmentType.helmet) {
          player.maxHp += equip.statValue;
          player.currentHp += equip.statValue;
        }
      }
    }

    // 2. 유물 능력치 적용
    for (final relic in Relic.allRelics) {
      // 보유 중인 유물이거나 레벨이 설정된 경우 적용
      final hasRelic = _relicInventory.containsKey(relic.id);
      int level = _relicLevels[relic.id] ?? 0;
      
      // 보유는 하고 있으나 레벨 데이터가 없는 경우 최소 Lv.1 적용
      if (hasRelic && level == 0) level = 1;
      if (level == 0) continue;

      final val = relic.getValue(level);
      switch (relic.id) {
        case 'relic_atk': player.baseAttack += val; break;
        case 'relic_def': player.baseDefense += val; break;
        case 'relic_hp': 
          player.maxHp += val; 
          player.currentHp += val;
          break;
        case 'relic_crit_chance': player.relicCritChanceBonus += val; break;
        case 'relic_crit_mult': player.relicCritMultBonus += val; break;
        case 'relic_atk_speed': player.relicAtkSpeedBonus += val; break;
        case 'relic_reroll': player.relicRerollBonus += val.toInt(); break;
        case 'relic_stun_dmg': player.relicStunExtraDamageRatio += val; break;
        case 'relic_extra_gold': player.relicExtraGold += val.toInt(); break;
        case 'relic_start_card': player.relicStartCardBonus += val.toInt(); break;
      }
    }
  }

  int _equipSubTabIndex = 0; // 0:무기, 1:방패, 2:모자

  Widget _buildEquipmentTab() {
    return SafeArea(
      child: Column(
        children: [
          // 상단 바 (골드 표시 등)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('장비 인벤토리', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                _buildGoldDisplay(),
              ],
            ),
          ),
          // 서브 탭 (무기, 방패, 모자)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSubTabItem(0, '무기'),
                _buildSubTabItem(1, '방패'),
                _buildSubTabItem(2, '모자'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // 장비 그리드
          Expanded(
            child: _buildEquipmentGrid(),
          ),
          const SizedBox(height: 130), // 네비게이션 바 공간
        ],
      ),
    );
  }

  Widget _buildSubTabItem(int index, String label) {
    bool isSelected = _equipSubTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _equipSubTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orangeAccent.withOpacity(0.2) : Colors.black45,
            border: Border.all(color: isSelected ? Colors.orangeAccent : Colors.white24),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.orangeAccent : Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEquipmentGrid() {
    final typeFilter = _equipSubTabIndex == 0 
        ? EquipmentType.sword 
        : (_equipSubTabIndex == 1 ? EquipmentType.shield : EquipmentType.helmet);
    
    // 해당 종류의 장비들만 필터링 (C1부터 S4까지 순서대로)
    List<String> items = [];
    for (int i = 1; i <= 16; i++) {
      final grade = Equipment.getGradeFromLevel(i).toLowerCase();
      final id = '${typeFilter.name}_$grade';
      if (_inventory.containsKey(id) || _equippedItems.containsValue(id)) {
        items.add(id);
      }
    }

    if (items.isEmpty) {
      return const Center(child: Text('보유 중인 장비가 없습니다.', style: TextStyle(color: Colors.white54)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final id = items[index];
        final count = _inventory[id] ?? 0;
        final isEquipped = _equippedItems.containsValue(id);
        final equip = Equipment.fromId(id);

        return GestureDetector(
          onTap: () => _showEquipmentDetail(equip),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEquipped ? Colors.cyanAccent : _getGradeColor(equip.grade),
                width: isEquipped ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/${equip.type.name}/${equip.id}.png', width: 40, height: 40,
                        errorBuilder: (context, error, stackTrace) => _buildGradeIcon(equip.grade)),
                      const SizedBox(height: 5),
                      Text(equip.grade, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 5,
                    bottom: 5,
                    child: Text('x$count', style: const TextStyle(color: Colors.yellowAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                if (isEquipped)
                  Positioned(
                    left: 5,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(4)),
                      child: const Text('E', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('B')) return Colors.blueAccent;
    if (grade.startsWith('A')) return Colors.purpleAccent;
    if (grade.startsWith('S')) return const Color(0xFFFFD700);
    return Colors.grey;
  }

  void _showEquipmentDetail(Equipment equip) {
    bool isEquipped = _equippedItems[equip.type.name] == equip.id;
    int count = _inventory[equip.id] ?? 0;
    bool canMerge = count >= 4 && equip.nextGradeId != null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _getGradeColor(equip.grade), width: 2),
              ),
              title: Center(
                child: Text(equip.name, style: TextStyle(color: _getGradeColor(equip.grade), fontWeight: FontWeight.bold)),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildGradeIcon(equip.grade),
                  const SizedBox(height: 20),
                  Text(
                    _getStatDescription(equip),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
               Text('보유 수량: $count개', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 장착/해제 버튼
                      ElevatedButton(
                        onPressed: (count > 0 || isEquipped) ? () async {
                          if (isEquipped) {
                            await _handleUnequip(equip.type.name);
                          } else {
                            await _handleEquip(equip.id, equip.type.name);
                          }
                          if (mounted) Navigator.pop(context);
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEquipped ? Colors.redAccent : Colors.cyanAccent,
                        ),
                        child: Text(isEquipped ? '해제' : '장착', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      // 합성 버튼
                      ElevatedButton(
                        onPressed: canMerge ? () async {
                          await _handleMerge(equip);
                          if (mounted) Navigator.pop(context);
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                        ),
                        child: const Text('합성', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _handleEquip(String id, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // 기존 장착 해제 및 새 장착 적용 (인벤토리 수량 조정 필요)
      Map<String, dynamic> updates = {};
      
      // 1. 현재 장착되어 있던 것이 있다면 인벤토리에 돌려줌
      String? oldEquippedId = _equippedItems[type];
      if (oldEquippedId != null) {
        updates['inventory.$oldEquippedId'] = FieldValue.increment(1);
      }

      // 2. 새로운 장착 아이템 인벤토리에서 1개 감소
      updates['inventory.$id'] = FieldValue.increment(-1);
      updates['equipped.$type'] = id;

      await userRef.update(updates);
      
      setState(() {
        if (oldEquippedId != null) {
          _inventory[oldEquippedId] = (_inventory[oldEquippedId] ?? 0) + 1;
        }
        _inventory[id] = (_inventory[id] ?? 0) - 1;
        if (_inventory[id] == 0) _inventory.remove(id);
        _equippedItems[type] = id;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('장비를 장착했습니다.')));
      }
    } catch (e) {
      debugPrint('Error equipping: $e');
    }
  }

  Future<void> _handleUnequip(String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? equippedId = _equippedItems[type];
    if (equippedId == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      await userRef.update({
        'inventory.$equippedId': FieldValue.increment(1),
        'equipped.$type': null,
      });
      
      setState(() {
        _inventory[equippedId] = (_inventory[equippedId] ?? 0) + 1;
        _equippedItems[type] = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('장비를 해제했습니다.')));
      }
    } catch (e) {
      debugPrint('Error unequipping: $e');
    }
  }

  Future<void> _handleMerge(Equipment equip) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? nextId = equip.nextGradeId;
    if (nextId == null) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      await userRef.update({
        'inventory.${equip.id}': FieldValue.increment(-4),
        'inventory.$nextId': FieldValue.increment(1),
      });
      
      setState(() {
        _inventory[equip.id] = (_inventory[equip.id] ?? 0) - 4;
        if (_inventory[equip.id]! <= 0) _inventory.remove(equip.id);
        _inventory[nextId] = (_inventory[nextId] ?? 0) + 1;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${equip.name} 4개를 합성하여 상위 장비를 획득했습니다!')));
      }
    } catch (e) {
      debugPrint('Error merging: $e');
    }
  }
}
