import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';

import 'package:newep/http/HttpPostData.dart' as http;

import '../../http/AdvertisingEnc.dart';
import '../../http/Encryption.dart';
import '../../http/StatisticsReporter.dart';
import '../../realm/SettingDBUtil.dart';
import '../../realm/UserDBUtil.dart';

class BleScanService {
  //instance 가져오기
  // FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  //스캔 결과 list
  List<ScanResult> scanResultList = [];
  //스캔 중인지 확인하는 stram
  StreamSubscription? subscription;
  StreamSubscription? resStream;
  StreamSubscription<List<int>>? valueStream;
  late Timer duration;
  //찾은 clober 저장하는 list
  Map<String, List> cloberList = {};
  Map<String, List> outCloberList = {};
  Map<String, List> skippedCloberList = {};

  //지금 스캔 중인가?
  bool _isScanning = false;
  bool timerValid = false;
  bool scanRestart = true;
  bool scanDone = false;
  bool searchDone = false;
  bool connecting = false;
  bool isAnd = Platform.isAndroid;

  //현재 확인 중인 clober의 값들
  late String cid;
  late num rssi;
  late String bat;

  //RSSI가 가장 커서 따로 저장한 clober 값들
  late String maxCid;
  late num maxRssi;
  late String maxBat;
  //RSSI MAX인 device 정보
  late ScanResult maxR;

  //Clober Key
  late int k1;
  late int k2;

  //경산용 Ev 처리
  bool isEv = false;
  //초기값 2000년 1월 1일 0시 0분 0초
  DateTime lastEv = DateTime(2000);
  DateTime lastGS = DateTime(2000);
  DateTime scanTime = DateTime.now();

  final String notFound = "none";
  late Encryption enc;
  late AdvertisingEnc advEnc;
  List<int>? prevAdver;
  late String preMaxCid;
  UserDBUtil db = UserDBUtil();

  //현재 스캔 중인지 확인함
  initBle() {
    subscription = FlutterBluePlus.isScanning.listen((isScanning) {
      _isScanning = isScanning;
    });
  }

  //initble의 스캔 여부 확인하는 listen 종료 (안해주면 더미로 남음)
  disposeBle() {
    subscription?.cancel();
    resStream?.cancel();
    valueStream?.cancel();
    debugPrint("dispose Scan");
  }

  //스캔 시작 .then이나 스캔 성공 여부 확인용 Future<bool>
  Future<bool> scan() async {
    scanResultList.clear();
    cloberList.clear();
    Future<bool>? returnValue;
    //이미 스캔 중인지 확인
    // debugPrint("Is Scanning? : $_isScanning");
    if (!_isScanning) {
      scanRestart = false;
      Future.delayed(const Duration(seconds: 1), (){
        debugPrint("1 Second !!!");
        timerValid = true;
      });
      timerStart();
      //기존 scan list 초기화
      scanResultList.clear();
      cloberList.clear();
      //스캔 시작
      FlutterBluePlus.startScan(
        //성능 설정
        androidScanMode: AndroidScanMode.lowLatency,
        //중복 scan 가능 설정
        oneByOne: true,
        //UUID filter 설정
        withServices: [Guid("00003559-0000-1000-8000-00805F9B34FB")],
        //시간초 설정 (4초)
        timeout: const Duration(minutes: 10)
      ).then((_) {
        timerStop();
        scanRestart = true;
        stopListen();
      });
      //스캔 결과 (list형태)가 나오면 가져와서 저장
      resStream = FlutterBluePlus.scanResults.listen((results) {
        scanResultList = results;
        for(ScanResult res in scanResultList) {
          if (cloberList[res.device.id.toString()] == null) {
            cloberList.addEntries({"${res.device.id}" : [res.rssi]}.entries);
          } else {
            if (cloberList[res.device.id.toString()]!.length >= 30) {
              cloberList[res.device.id.toString()]?.removeAt(0);
            }
            cloberList[res.device.id.toString()]?.add(res.rssi);
          }
        }
        //searchClober();
      });
      returnValue = Future.value(true);
    } else {
      //이미 작동 중이었으면 넘어감
      debugPrint("Scanning...");
      returnValue = Future.value(false);
    }

    return returnValue;
  }

  //스캔 중단
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    resStream?.cancel();
    debugPrint("stop Scan");
  }
  void stopListen() {
    if (resStream != null) {
      resStream!.cancel();
    }
    if(!isAnd) {
      if (valueStream != null) {
        valueStream!.cancel();
      }
    }
  }

  //scan 결과 중에 clober 찾기
  Future<bool> searchClober() async {
    // debugPrint("Start Search!!");
    Future<bool>? returnValue;
    isEv = false;
    int forwardRssi = -100;
    int backRssi = -100;
    //기존 RSSI MAX 값들 초기화
    clearMax();
    List<ScanResult> scanResultListCopy = List.from(scanResultList);
    // debugPrint("Length Check : ${scanResultList.length}");
    Map<String, List> cloberListCopy = Map.from(cloberList);
    outCloberList.clear();
    skippedCloberList.clear();

    for (int i = 0; i < scanResultListCopy.length; i++) {
      ScanResult res = scanResultListCopy[i];
      //ScanResult.advertisementData.manufactureData에 회사 확인이나 CID 등등 값들 있음 (공유되는 Clober 이미지 참고)
      int recordTime = DateTime.now().millisecondsSinceEpoch - res.timeStamp.millisecondsSinceEpoch;
      if (recordTime > 2*1000) {
        continue;
      }
      var manu = res.advertisementData.manufacturerData;
      //map의 형태로 반환됨
      if(manu.keys.toList().isNotEmpty){
        //주의
        //이미지 기준 byte 11 부터 시작함 (회사코드 L 부분 / Y5LZ 중에)
        //Y5 값(9~10byte)은 map의 key값으로 배정됨
        //정확한 이유는 아직 못 찾음 (패키지 내용 확인 필요)

        // 9, 10byte값 map key로 가져오기
        // Y = 0x59 , 5 = 0x35
        // 13657 -> 3559 (dec to hex) -> 5 Y
        // key 값이 왜 10,9 byte 역순인 이유도 정확히 파악 안됨
        int a = manu.keys.toList().first;
        List code = [manu[a]?[0], manu[a]?[1]];
        List coop = [76, 90];
        List cidlist = [manu[a]?[4], manu[a]?[5], manu[a]?[6], manu[a]?[7]];

        if(listEquals(code, coop) && a == 13657){
          // debugPrint("yes Clober");
        } else {
          // debugPrint("no Clober");
          returnValue = Future.value(false);
          // debugPrint("==================");
          continue;
        }

        //clober 종류 확인 (출입용 + 방향)
        List code2 = [manu[a]?[2], manu[a]?[3]];
        // debugPrint("출입 확인 : ${code2.toString()}");
        // debugPrint("CID 확인 : ${cidlist.toString()}");
        if(listEquals(code2, [1, 1])) {
          // debugPrint("manu Check : $manu");
          if (manu[a]!.length < 19) {
            // debugPrint("short manu pass");
            continue;
          }
          // debugPrint("현재 key값 : [${manu[a]?[8]},${manu[a]?[9]}]");

          debugPrint("manu Check : ${manu[a]}");
          List<int> adverCheck = List.from(manu[a]!.sublist(10,19));
          debugPrint("new List Check : $adverCheck");

          if (prevAdver != null) {
            // debugPrint("prev List check : $prevAdver");
            if (listEquals(adverCheck, prevAdver)) {
              // debugPrint("Adv 성공!");
              await FlutterBlePeripheral().stop();
              evCall();
            }
          }
          if (manu[a]?[8] == 0) {
            // debugPrint("invalid Clober. 너무 멀거나, 움직임 필요");
            // debugPrint("==================");
            continue;
          }
          //정면 Clober는 RSSI 평균 계산 후 후면 Clober RSSI 평균이 있으면 진행, 아니면 ScanResultList마지막에 다시 추가하고 continue
          //이미 후면 Clober RSSI가 있는 정면 Clober만 진행시킴으로 Clober가 여러개여도 구분 가능
          // debugPrint("ID Check : ${res.device.id}");
          // debugPrint("Get List : ${cloberListCopy[res.device.id.toString()]}");
          int sum = 0;
          List? tempList = cloberListCopy[res.device.id.toString()];
          // debugPrint("Length Check : ${tempList?.length}");
          if (tempList != null) {
            for (int a in tempList) {
              sum += a;
            }
          }
          //쿨타임 3분으로 (계속 눌리면 EV문이 계속 열리니)
          //Clober ID로 EV용 구별
          bool isGS = manu[a]![6] == 2 && manu[a]![7] > 25 && manu[a]![7] < 45;
          int restTime = DateTime.now().millisecondsSinceEpoch - lastEv.millisecondsSinceEpoch;
          if (restTime < 3*1000 && !isGS){
            // debugPrint("But Cooldown ... (3 sec / ${restTime~/1000})");
            continue;
          }

          //후면 Clober RSSI가 저장되어 있는지 확인
          if (isAnd && !isAnd && outCloberList["${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}"] == null) {
            // debugPrint("Before Input South!!");
            // debugPrint("==================");
            //두번 skip은 짝인 1.3 Clober가 없다고 판단 pass
            if (skippedCloberList["${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}"] != null) {
              // debugPrint("Arleady Skipped Clober!!");
              // debugPrint("==================");
              continue;
            }
            //단 경산용 EV Clober는 따로 처리 (정면 밖에 없음)
            //경산 EV 쿨타임 5분
            int restGSTime = DateTime.now().millisecondsSinceEpoch - lastGS.millisecondsSinceEpoch;
            if (isGS) {
              // debugPrint("But EvClober");
              if (restGSTime < 5*60*1000) {
                //유저 설정 확인
                SettingDataUtil setdb = SettingDataUtil();
                bool auto = setdb.getAutoFlowSelectState();

                //유저가 거부 해놨으면 pass
                if (auto) {
                  //후면 RSSI도 있다고 치고 정면이랑 같은 값 넣어줌
                  //EV Clober가 가장 가까이 있으면 결국 이게 MAX RSSI가 될 것
                  forwardRssi = sum ~/ tempList!.length;
                  backRssi = forwardRssi;
                  isEv = true;
                } else {
                  continue;
                }
              } else {
                // debugPrint("But EVCooldown ... (5 minute / ${restGSTime~/1000})");
              }
            } else {
              //없으면 지금의 Clober를 list 맨 뒤로 보내고 continue (후면 인식되면 정면 되게)
              scanResultListCopy.add(res);
              skippedCloberList.addEntries({"${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}" : [backRssi]}.entries);
              continue;
            }
          } else {
            //후면 RSSI 평균이 있으면 읽어와서 back에 넣어줌 forward는 계산
            forwardRssi = sum~/tempList!.length;
            if (isAnd || !isAnd) {
              backRssi = forwardRssi;
            } else {
              backRssi = outCloberList["${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}"]?.first;
            }
            // debugPrint("Input North");
            // debugPrint("Fore : $forwardRssi, Back : $backRssi");
          }
          //정면
        } else if (listEquals(code2, [1, 3])) {
          if (isAnd || !isAnd) {
            // debugPrint("Not Use in Android");
            continue;
          }
          //후면 Clober는 RSSI 평균 값만 저장하고 continue
          //outCloberList에 Clober ID를 key값으로 RSSI 평균을 저장함(정면, 후면 Clober ID가 같음)
          // debugPrint("ID Check : ${res.device.id}");
          // debugPrint("Get List : ${cloberListCopy[res.device.id.toString()]}");
          int sum = 0;
          List? tempList = cloberListCopy[res.device.id.toString()];
          if (tempList != null) {
            for (int a in tempList) {
              sum += a;
            }
          }
          backRssi = sum~/tempList!.length;
          // debugPrint("Input South");
          outCloberList.addEntries({"${manu[a]![4]}.${manu[a]![5]}.${manu[a]![6]}.${manu[a]![7]}" : [backRssi]}.entries);
          // debugPrint("==================");
          continue;
          //후면
        } else {
          //출입용 아니면 그냥 pass
          // debugPrint("Not Input Pass");
          // debugPrint("==================");
          continue;
        }
        cid = "";
        bat = manu[a]![8].toString();

        //package에서 주는 값은 dec임 hex로 변환
        if (cidlist[0] < 16) {
          cid += "0";
        }
        cid += cidlist[0].toRadixString(16).toString();
        if (cidlist[1] < 16) {
          cid += "0";
        }
        cid += cidlist[1].toRadixString(16).toString();
        if (cidlist[2] < 16) {
          cid += "0";
        }
        cid += cidlist[2].toRadixString(16).toString();
        if (cidlist[3] < 16) {
          cid += "0";
        }
        cid += cidlist[3].toRadixString(16).toString();

        if (db.findCloberByCIDIsEmpty(cid)) {
          // debugPrint("접근할 수 없는 Clober 입니다. CID : $cid");
          continue;
        }
        rssi = (forwardRssi + backRssi)/2;
        //스캔된 device 값 확인 (clober라면)
        // debugPrint("==================");
        // debugPrint("cid : $cid\nrssi : $rssi\nbat : $bat");
        // debugPrint("==================");
        //RSSI 최대값 비교
        //우선 isEv를 읽어 이게 EV용 Clober인지 확인
        double correctRssi = Platform.isAndroid ? -75 : -80;
        correctRssi = correctRssi - SettingDataUtil().getUserSetRange();
        // debugPrint("보정된 RSSI : $correctRssi");
        if (isEv && rssi > maxRssi && rssi > correctRssi) {
          // debugPrint("New Max with Ev");
          maxCid = cid;
          maxRssi = rssi;
          maxBat = bat;
          maxR = res;
          searchDone = false;
          returnValue = Future.value(true);
        } else if ((rssi > maxRssi) && code2[0] == 1 && rssi > correctRssi) {
          //EV용 Clober가 이미 인식되어 있더라도
          //다른 Clober가 max 갱신되면 isEv = false
          // debugPrint("New Max");
          maxCid = cid;
          maxRssi = rssi;
          maxBat = bat;
          maxR = res;
          isEv = false;
          searchDone = true;
          returnValue = Future.value(true);
        } else {
          // debugPrint("Not Max");
        }
      } else {
        // debugPrint("Pass");
        returnValue = Future.value(false);
      }
    }

    scanDone = false;
    // debugPrint("Search Done? : $searchDone");
    if (db.findCloberByCIDIsEmpty(maxCid)) {
      // debugPrint("접근할 수 없는 Clober 입니다. CID : $maxCid");
      searchDone = false;
    } else {
      var temp = db.findCloberByCID(maxCid);
      debugPrint(temp.cloberid);
    }
    if (!searchDone) {
      if (isEv) {
        // debugPrint("경산 Ev Search");
        callEvGyeongSan();
      } else {
        // debugPrint("Search 실패");
        timerValid = true;
        // debugPrint("Time Valid True");
      }
    }
    return returnValue ?? Future.value(false);
  }

  Future<bool> callEvGyeongSan() async {
    //경산 EvCall한 시간 갱신
    int restTime = DateTime.now().millisecondsSinceEpoch - lastEv.millisecondsSinceEpoch;
    lastGS = DateTime.now();
    //전화 번호
    String phoneNumber = db.getUser().phoneNumber;
    //호수
    String ho = db.getDong()[1];
    //통신 (밖에서 부르는 것이므로 isInward false로)
    String result;
    if (restTime < 2*60*1000) {
      //집에서 밖으로
      result = await http.evCallGyeongSan(phoneNumber, false, maxCid, ho);
    } else {
      //밖에서 집으로
      result = await http.evCallGyeongSan(phoneNumber, true, maxCid, ho);
    }
    debugPrint("통신 결과 : $result");
    timerValid = true;
    if (result == "통신error") {
      StatisticsReporter().sendError('경산 엘베 call 에러', db.getUser().phoneNumber);
      return false;
    } else {
      return true;
    }
  }

  //maxCid 설정 여부로 clober 검색 여부 확인
  bool findClober() {
    if (maxCid == notFound) {
      return false;
    }
    return true;
  }

  //max 초기값
  void clearMax() {
    maxCid = notFound;
    //신호 세기 조절
    //-100이 신호 최소치 Android 소스코드 기준 옵션으로 -75 ~ -95 로 조절 가능
    maxRssi = -100;
    maxBat = notFound;
  }

  //BLE 연결
  Future<bool> connect() async {
    Future<bool>? returnValue;
    searchDone = false;
    connecting = true;
    bool isFail = false;
    bool callev = false;
    bool startSuccess = false;
    //연결 시도 (ScanResult.device에서 .connect로 함)
    await maxR.device
        .connect(autoConnect: false)
    //시간제한 설정
        .timeout(const Duration(milliseconds: 2000), onTimeout: () {
          debugPrint('Fail BLE Connect');
          returnValue = Future.value(false);
          isFail = true;
    });
    if (isFail) {
      timerValid = true;
      return returnValue ?? Future.value(false);
    }
    debugPrint('connect');
    returnValue = Future.value(true);

    //device 내 service 검색
    late List<BluetoothService> services;
    try {
      services = await maxR.device.discoverServices()
          .timeout(const Duration(milliseconds: 1500));
    } on TimeoutException catch (_) {
      debugPrint('Fail Service Search');
      returnValue = Future.value(false);
      isFail = true;
    }
    if (isFail) {
      timerValid = true;
      return returnValue ?? Future.value(false);
    }

    //key값 가져오기용 manufacturerData 미리 가져오기 (19, 20byte에 key 값)
    Map<int, List<int>> readData = maxR.advertisementData.manufacturerData;
    //map의 key값 가져오기
    int a = readData.keys.toList().first;
    debugPrint("manu Check : ${readData[a]}");
    //출입용 Clober의 1번 안테나 저장용
    //1번 안테나 write용, 2번 안테나 read용
    late BluetoothCharacteristic char1;
    for (var service in services) {
      List<int> listenValue;
      var characteristics = service.characteristics;

      //Service UUID로 목표 Service 찾기
      List<String> temp = service.uuid.toString().split("-");
      debugPrint(temp[0]);
      //iOS 기준 Service UUID의 첫 부분만으로 serch하기에 일단 따라함
      //ex. 0000-1111-2222-3333이 UUID이면 -으로 나눠서 첫번째 0000
      //찾는 service의 UUID값 3559 (0채워서)
      if (temp[0] == "00003559") {
        debugPrint("목표 Service");
      } else {
        continue;
      }

      //Service 안에 목표인 Characteristic 찾기
      //구조 device -> service -> characteristic
      for (BluetoothCharacteristic c in characteristics) {
        debugPrint('Character 구조 : ${c.toString()}');
        debugPrint('Character UUID : ${c.uuid}');

        List<String> temp2 = c.uuid.toString().split("-");
        debugPrint(temp2[0]);
        //Service 때와 같이 Charateristic UUID로 목표 찾기
        //1은 wirte용 2는 read용
        if (temp2[0] == "00000002") {
          debugPrint("목표 Charateristic");
          debugPrint("Notifying Check : ${c.isNotifying}");
          debugPrint("Readable Check : ${c.properties.read}");
          debugPrint("Notify Check : ${c.properties.notify}");
          await c.setNotifyValue(true);
          await char1.setNotifyValue(true);
          //write 이후 characteristic의 response를 얻는 listener
          valueStream = c.onValueChangedStream.listen((value) async {
            //loading은 바로 해제
            debugPrint('!!!!!Value Changed');
            listenValue = value;
            debugPrint('!!!!!Value check : $listenValue');
            //write 실패시 []가 읽혀옴
            //startSuccess 값으로 순서 구분
            if (listenValue.isEmpty && !startSuccess) {
              debugPrint("StartWrite 실패");
            } else if (!startSuccess){
              k1 = listenValue[4];
              k2 = listenValue[5];
              startSuccess = true;
              debugPrint("StartWrite 성공");
              //startSuccess가 true이면 암호화 단계로 인식
              //암호화 성공시 [80]이 읽힘
            } else if (listenValue.first == 80) {
              //EV 불러오는 것을 허가
              callev = true;
              debugPrint("암호화 성공 : $callev");
            } else {
              debugPrint("암호화 실패");
            }
          });

          //연결은 이미 되어 있으므로 목표 Characteristic에 START라는 신호를 write해줌
          //START 신호 생성 (정확히는 cloberID 4자리 + START)
          debugPrint("Start Write 시작");
          List<int> start = [readData[a]![4], readData[a]![5], readData[a]![6], readData[a]![7], 0x53, 0x54, 0x41, 0x52, 0x54];
          //저장돼 있던 write용 Characteristic에 write 진행
          await char1.write(start, withoutResponse: true);
          debugPrint("Waiting Reponse...");
          await Future.delayed(const Duration(milliseconds: 500));
          if (!startSuccess) {
            valueStream?.cancel();
            debugPrint("Start Write를 실패했습니다.");
            timerValid = true;
            return Future.value(false);
          }
          //위의 onValueChangedStream에서 Response를 읽어옴
          debugPrint('Key1 Check : $k1');
          debugPrint('Key2 Check : $k2');
          debugPrint('Clober ID : $maxCid');

          debugPrint("Notifying Check : ${c.isNotifying}");

          //암호화 시작 부분
          debugPrint("암호화 시작");
          var finds2 = db.findCloberByCID(maxCid);
          enc = Encryption(finds2.userid, maxCid, finds2.pk, k1, k2);
          enc.init();
          enc.startEncryption();
          debugPrint("Encryption Write 시작");
          debugPrint("Encryption 확인 : ${enc.result}");

          await char1.write(enc.result, withoutResponse: true);
          debugPrint('Read Value : ${c.lastValue}');
          debugPrint("Waiting Reponse...");
          await Future.delayed(const Duration(milliseconds: 500));

          //암호화 성공했으면 EV Call 실행
          if (callev) {
            await evCall();
          } else {
            valueStream?.cancel();
            debugPrint("암호화를 실패했습니다.");
            StatisticsReporter().sendError('암호화 실패', db.getUser().phoneNumber);
            timerValid = true;
            return Future.value(false);
          }
          valueStream?.cancel();
        } else {
          //1일 때는 write용이므로 일단 char1에 저장해두고 read용인 2찾으러가기
          debugPrint("Write Charateristic");
          char1 = c;
        }
      }
    }

    timerValid = true;
    return returnValue ?? Future.value(false);
  }

  //connect된 BLE 끊기
  Future<void> disconnect() async {
    debugPrint("Disconnecting...");
    if (connecting) {
      connecting = false;
      valueStream?.cancel();
      maxR.device.disconnect();
    }
  }

  //Android도 Connect하면서 안씀 일단 냅둠
  Future<void> writeBle() async {
    searchDone = false;
    debugPrint('write BLE');
    Map<int, List<int>> readData = maxR.advertisementData.manufacturerData;
    int a = readData.keys.toList().first;
    var finds2 = db.findCloberByCID(maxCid);
    debugPrint("USER ID 확인 : ${finds2.userid}");
    k1 = readData[a]![8];
    k2 = readData[a]![9];
    debugPrint("manufactureData Check : $readData");
    debugPrint("manufactureData Check : ${readData[a]!.runtimeType}");
    debugPrint('Key1 Check : $k1');
    debugPrint('Key2 Check : $k2');

    advEnc = AdvertisingEnc(k1.toString(),k2.toString(),finds2.userid);
    advEnc.startEncryption();
    prevAdver = advEnc.result;
    debugPrint("Advertising Check : ${advEnc.result}");


    //암호화 시작
    debugPrint("암호화 시작");
    enc = Encryption(finds2.userid, maxCid, finds2.pk, k1, k2);
    enc.init();
    enc.startEncryption();
    debugPrint("Encryption 확인 : ${enc.result}");

    List<int> bytes = [readData[a]![4], readData[a]![5], readData[a]![6], readData[a]![7]];
    debugPrint("Bytes 확인 : $bytes");
    AdvertiseData advertiseData = AdvertiseData(
      manufacturerId: 117,
      manufacturerData: Uint8List.fromList([...bytes, ...enc.result]),
    );
    debugPrint("Data 생성, ${advertiseData.manufacturerData}");

    final AdvertiseSettings advertiseSettings = AdvertiseSettings(
      advertiseMode: AdvertiseMode.advertiseModeLowLatency,
      txPowerLevel: AdvertiseTxPower.advertiseTxPowerMedium,
      connectable: true,
      timeout: 5000,
    );

    BluetoothPeripheralState response;
    response = await FlutterBlePeripheral().start(
        advertiseData: advertiseData,
        advertiseSettings: advertiseSettings
    );
    preMaxCid = maxCid;
    timerValid = true;

    debugPrint("response : $response");
  }

  Future<void> evCall() async {
    try {
      String result;
      result = await http.cloberPass(1, cid, maxRssi.toString());
      debugPrint("통신 결과2212222 : $result");
      //전화 번호
      db.getDB();
      String phoneNumber = db
          .getUser()
          .phoneNumber;
      String httpResult;

      if (isAnd) {
        debugPrint("test : $preMaxCid");
        httpResult = await http.evCall(preMaxCid, phoneNumber);
      } else {
        httpResult = await http.evCall(maxCid, phoneNumber);
      }
      debugPrint("통신 결과333333333 : $httpResult");
      //최신 lastInCloberID 갱신
      SettingDataUtil set = SettingDataUtil();
      set.setLastInCloberID(maxCid);

      lastEv = DateTime.now();
    } catch (e) {
      debugPrint("Error log : ${e.toString()}");
      StatisticsReporter().sendError('서버 통신 실패.', db.getUser().phoneNumber);
      valueStream?.cancel();
    }
    prevAdver = null;
    timerValid = true;
  }

  void timerStart() {
    duration = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      //if (timerValid && counter > 15) {
      if (timerValid) {
        DateTime nowTime = DateTime.now();
        if (nowTime.millisecondsSinceEpoch-scanTime.millisecondsSinceEpoch > 1000) {
          // debugPrint("Scan Cut !!!");
          //debugPrint("Scan Length : ${scanResultList.length}");
          timerValid = false;
          scanDone = true;
          scanTime = nowTime;
        }
      }
    });
  }

  void timerStop() {
    duration.cancel();
  }
}