class SignTranslator {
  static String translate(String label, bool isEn) {
    if (!isEn) return label.toUpperCase();
    
    final l = label.toLowerCase();
    
    final map = {
      'bắt đầu đường ưu tiên': 'Start of priority road',
      'cấm đi thẳng': 'No going straight',
      'cấm đỗ': 'No parking',
      'cấm đường cấm': 'Closed road',
      'cấm ngược chiều': 'No entry',
      'cấm ô tô': 'No cars',
      'cấm quay đầu xe': 'No U-turn',
      'cấm rẽ': 'No turning',
      'cấm sử dụng còi xe': 'No honking',
      'cấm vượt': 'No overtaking',
      'cấm dừng, đỗ': 'No stopping or parking',
      'cấm rẽ phải': 'No right turn',
      'cấm rẽ, quay đầu phải': 'No right turn or U-turn',
      'cấm rẽ, quay đầu trái': 'No left turn or U-turn',
      'cấm rẽ trái': 'No left turn',
      'chỉ được đi thẳng': 'Go straight only',
      'chỉ được rẽ phải': 'Turn right only',
      'chỉ được rẽ trái': 'Turn left only',
      'chú ý chỗ ngoặt nguy hiểm': 'Dangerous curve ahead',
      'chú ý công trình': 'Roadworks ahead',
      'chú ý địa điểm thường xảy ra tai nạn': 'Accident-prone area',
      'chú ý đi chậm': 'Slow down',
      'chú ý đường hai chiều': 'Two-way traffic ahead',
      'chú ý đường giao nhau': 'Intersection ahead',
      'chú ý đường không bằng phẳng': 'Bumpy road',
      'chú ý đường trơn': 'Slippery road',
      'chú ý đường đôi': 'Dual carriageway ahead',
      'chú ý đường hẹp': 'Narrow road ahead',
      'chú ý giao đường khuất tầm nhìn': 'Blind intersection',
      'chú ý giao đường ưu tiên': 'Yield to priority road',
      'chú ý hầm chui': 'Tunnel ahead',
      'chú ý hết đường đôi': 'End of dual carriageway',
      'chú ý người đi bộ': 'Pedestrian crossing ahead',
      'chú ý tín hiệu đèn': 'Traffic signals ahead',
      'chú ý trẻ em': 'Children crossing ahead',
      'hết lệnh cấm': 'End of all restrictions',
      'hướng phải đi tránh vật cản': 'Keep right of obstacle',
      'kết thúc đường ưu tiên': 'End of priority road',
      'khu vực đông dân cư': 'Populated area',
      'ngoài khu vực đông dân cư': 'Out of populated area',
      'dừng lại': 'Stop',
      'vòng xuyến': 'Roundabout',
    };

    if (map.containsKey(l)) {
      return map[l]!.toUpperCase();
    }

    if (l.startsWith('hạn chế chiều cao')) {
      final height = RegExp(r'\d+\.\d+').firstMatch(l)?.group(0) ?? '';
      return 'HEIGHT LIMIT ${height}M';
    }
    
    if (l.startsWith('tốc độ tối đa')) {
      final speed = RegExp(r'\d+').firstMatch(l)?.group(0) ?? '';
      return 'MAXIMUM SPEED $speed KM/H';
    }

    if (l.startsWith('tốc độ tối thiểu')) {
      final speed = RegExp(r'\d+').firstMatch(l)?.group(0) ?? '';
      return 'MINIMUM SPEED $speed KM/H';
    }
    
    if (l.startsWith('hết tốc độ tối đa')) {
      final speed = RegExp(r'\d+').firstMatch(l)?.group(0) ?? '';
      return 'END OF MAX SPEED $speed KM/H';
    }

    return label.toUpperCase();
  }
}
