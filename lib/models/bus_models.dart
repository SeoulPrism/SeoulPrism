/// 서울시 버스 데이터 모델

/// 실시간 버스 위치 정보
class BusPosition {
  final String vehId;       // 차량 ID
  final String plainNo;     // 차량번호 (예: 서울74사1234)
  final double lat;         // 위도 (posY / tmY)
  final double lng;         // 경도 (posX / tmX)
  final int stopFlag;       // 정류소 도착 여부 (0: 운행중, 1: 도착)
  final int busType;        // 차량유형 (0: 일반, 1: 저상)
  final int congestion;     // 혼잡도 (0~6)
  final String? lastStNm;   // 마지막 정류소명
  final int? sectOrd;       // 구간 순번

  BusPosition({
    required this.vehId,
    required this.plainNo,
    required this.lat,
    required this.lng,
    required this.stopFlag,
    required this.busType,
    required this.congestion,
    this.lastStNm,
    this.sectOrd,
  });

  factory BusPosition.fromXml(Map<String, String> fields) {
    return BusPosition(
      vehId: fields['vehId'] ?? '',
      plainNo: fields['plainNo'] ?? '',
      lat: double.tryParse(fields['gpsY'] ?? fields['tmY'] ?? fields['posY'] ?? '0') ?? 0,
      lng: double.tryParse(fields['gpsX'] ?? fields['tmX'] ?? fields['posX'] ?? '0') ?? 0,
      stopFlag: int.tryParse(fields['stopFlag'] ?? '0') ?? 0,
      busType: int.tryParse(fields['busType'] ?? '0') ?? 0,
      congestion: int.tryParse(fields['congetion'] ?? fields['congestion'] ?? '0') ?? 0,
      lastStNm: fields['lastStnNm'] ?? fields['lastStTm'],
      sectOrd: int.tryParse(fields['sectOrd'] ?? ''),
    );
  }
}

/// 버스 도착 정보
class BusArrivalInfo {
  final String stId;        // 정류소 ID
  final String stNm;        // 정류소명
  final String busRouteId;  // 노선 ID
  final String rtNm;        // 노선명 (예: 143, 301)
  final String arrmsg1;     // 첫번째 버스 도착 메시지
  final String arrmsg2;     // 두번째 버스 도착 메시지
  final int? traTime1;      // 첫번째 버스 도착 예정 시간(초)
  final int? traTime2;      // 두번째 버스 도착 예정 시간(초)
  final String? plainNo1;   // 첫번째 차량번호
  final String? plainNo2;   // 두번째 차량번호
  final int? congestion1;   // 첫번째 혼잡도
  final int? congestion2;   // 두번째 혼잡도
  final bool isLast1;       // 막차 여부
  final bool isLast2;
  final bool isFull1;       // 만차 여부
  final bool isFull2;
  final int? term;          // 배차간격(분)

  BusArrivalInfo({
    required this.stId,
    required this.stNm,
    required this.busRouteId,
    required this.rtNm,
    required this.arrmsg1,
    required this.arrmsg2,
    this.traTime1,
    this.traTime2,
    this.plainNo1,
    this.plainNo2,
    this.congestion1,
    this.congestion2,
    this.isLast1 = false,
    this.isLast2 = false,
    this.isFull1 = false,
    this.isFull2 = false,
    this.term,
  });

  factory BusArrivalInfo.fromXml(Map<String, String> fields) {
    return BusArrivalInfo(
      stId: fields['stId'] ?? '',
      stNm: fields['stNm'] ?? '',
      busRouteId: fields['busRouteId'] ?? '',
      rtNm: fields['rtNm'] ?? '',
      arrmsg1: fields['arrmsg1'] ?? '정보없음',
      arrmsg2: fields['arrmsg2'] ?? '정보없음',
      traTime1: int.tryParse(fields['traTime1'] ?? ''),
      traTime2: int.tryParse(fields['traTime2'] ?? ''),
      plainNo1: fields['plainNo1'],
      plainNo2: fields['plainNo2'],
      congestion1: int.tryParse(fields['reride_Num1'] ?? ''),
      congestion2: int.tryParse(fields['reride_Num2'] ?? ''),
      isLast1: fields['isLast1'] == '1',
      isLast2: fields['isLast2'] == '1',
      isFull1: fields['full1'] == '1',
      isFull2: fields['full2'] == '1',
      term: int.tryParse(fields['term'] ?? ''),
    );
  }
}

/// 버스 노선 정보
class BusRouteInfo {
  final String busRouteId;   // 노선 ID
  final String busRouteNm;   // 노선명 (예: 143)
  final int routeType;       // 노선유형 (3: 간선, 4: 지선, 5: 순환, 6: 광역, 7: 인천, 8: 경기)
  final String stStationNm;  // 기점 정류소명
  final String edStationNm;  // 종점 정류소명
  final String? firstBusTm;  // 첫차 시간
  final String? lastBusTm;   // 막차 시간
  final int? term;           // 배차간격(분)

  BusRouteInfo({
    required this.busRouteId,
    required this.busRouteNm,
    required this.routeType,
    required this.stStationNm,
    required this.edStationNm,
    this.firstBusTm,
    this.lastBusTm,
    this.term,
  });

  factory BusRouteInfo.fromXml(Map<String, String> fields) {
    return BusRouteInfo(
      busRouteId: fields['busRouteId'] ?? '',
      busRouteNm: fields['busRouteNm'] ?? '',
      routeType: int.tryParse(fields['routeType'] ?? '0') ?? 0,
      stStationNm: fields['stStationNm'] ?? '',
      edStationNm: fields['edStationNm'] ?? '',
      firstBusTm: fields['firstBusTm'],
      lastBusTm: fields['lastBusTm'],
      term: int.tryParse(fields['term'] ?? ''),
    );
  }

  /// 노선 색상 (노선유형 기준)
  String get routeTypeLabel => switch (routeType) {
    3 => '간선',
    4 => '지선',
    5 => '순환',
    6 => '광역',
    7 => '인천',
    8 => '경기',
    9 => '폐지',
    _ => '기타',
  };
}

/// 버스 정류소 정보
class BusStationInfo {
  final String stId;      // 정류소 고유 ID
  final String arsId;     // 정류소 번호 (5자리, 안내용)
  final String stNm;      // 정류소명
  final double lat;       // 위도
  final double lng;       // 경도

  BusStationInfo({
    required this.stId,
    required this.arsId,
    required this.stNm,
    required this.lat,
    required this.lng,
  });

  factory BusStationInfo.fromXml(Map<String, String> fields) {
    return BusStationInfo(
      stId: fields['stId'] ?? '',
      arsId: fields['arsId'] ?? '',
      stNm: fields['stNm'] ?? '',
      lat: double.tryParse(fields['tmY'] ?? fields['posY'] ?? '0') ?? 0,
      lng: double.tryParse(fields['tmX'] ?? fields['posX'] ?? '0') ?? 0,
    );
  }
}

/// 노선의 정류소 순서 정보
class BusRouteStation {
  final String stId;
  final String arsId;
  final String stNm;
  final int seq;          // 정류소 순번
  final double lat;
  final double lng;
  final String? direction; // 방향

  BusRouteStation({
    required this.stId,
    required this.arsId,
    required this.stNm,
    required this.seq,
    required this.lat,
    required this.lng,
    this.direction,
  });

  factory BusRouteStation.fromXml(Map<String, String> fields) {
    return BusRouteStation(
      stId: fields['station'] ?? fields['stId'] ?? '',
      arsId: fields['arsId'] ?? '',
      stNm: fields['stationNm'] ?? fields['stNm'] ?? '',
      seq: int.tryParse(fields['seq'] ?? '0') ?? 0,
      lat: double.tryParse(fields['gpsY'] ?? fields['tmY'] ?? fields['posY'] ?? '0') ?? 0,
      lng: double.tryParse(fields['gpsX'] ?? fields['tmX'] ?? fields['posX'] ?? '0') ?? 0,
      direction: fields['direction'],
    );
  }
}
