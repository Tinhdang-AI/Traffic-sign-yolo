import 'package:flutter/material.dart';

class TrafficSignIcon extends StatelessWidget {
  final String label;
  final double size;

  const TrafficSignIcon({
    super.key,
    required this.label,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final l = label.toLowerCase();

    if (l.contains('cấm đỗ') || l.contains('cấm dừng')) {
      return _buildNoParking(l);
    } else if (l.contains('cấm ngược chiều')) {
      return _buildNoEntry();
    } else if (l.contains('cấm đường cấm')) {
      return _buildClosedRoad();
    } else if (l.startsWith('cấm') || l.contains('hạn chế chiều cao')) {
      return _buildProhibitionSign(l);
    } else if (l.startsWith('chú ý')) {
      return _buildWarningSign(l);
    } else if (l.startsWith('tốc độ tối đa')) {
      return _buildMaxSpeedSign(l);
    } else if (l.startsWith('tốc độ tối thiểu')) {
      return _buildMinSpeedSign(l);
    } else if (l.startsWith('chỉ được') || l == 'vòng xuyến' || l.contains('hướng phải đi')) {
      return _buildMandatorySign(l);
    } else if (l == 'dừng lại') {
      return _buildStopSign();
    } else if (l.contains('đường ưu tiên')) {
      return _buildPrioritySign(l);
    } else if (l.contains('dân cư')) {
      return _buildCitySign(l);
    } else if (l.startsWith('hết tốc độ') || l.startsWith('hết lệnh cấm')) {
      return _buildEndRestrictionSign(l);
    } else {
      return _buildFallback();
    }
  }

  Widget _buildProhibitionSign(String l) {
    if (l.contains('chiều cao')) {
      final match = RegExp(r'\d+\.\d+').firstMatch(l);
      final height = match != null ? match.group(0) : '4.3';
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.red, width: size * 0.12),
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: _HeightLimitPainter(),
          ),
          Container(
            width: size * 0.6,
            height: size * 0.4,
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${height}m',
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (l.contains('vượt')) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.red, width: size * 0.12),
            ),
          ),
          Positioned(
            left: size * 0.18,
            child: Icon(Icons.directions_car, size: size * 0.38, color: Colors.red),
          ),
          Positioned(
            right: size * 0.18,
            child: Icon(Icons.directions_car, size: size * 0.38, color: Colors.black),
          ),
          Transform.rotate(
            angle: -0.785398,
            child: Container(
              width: size * 0.08,
              height: size * 0.8,
              color: Colors.red,
            ),
          ),
        ],
      );
    }

    IconData? iconData;
    if (l.contains('ô tô')) iconData = Icons.directions_car;
    else if (l.contains('còi')) iconData = Icons.campaign; // Megaphone horn
    else if (l.contains('quay đầu')) iconData = Icons.u_turn_left;
    else if (l.contains('rẽ phải')) iconData = Icons.turn_right;
    else if (l.contains('rẽ trái')) iconData = Icons.turn_left;
    else if (l.contains('đi thẳng')) iconData = Icons.arrow_upward;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.red, width: size * 0.15),
          ),
        ),
        if (iconData != null)
          Icon(iconData, size: size * 0.45, color: Colors.black),
        Transform.rotate(
          angle: -0.785398, // -45 degrees (bottom left to top right)
          child: Container(
            width: size * 0.1,
            height: size * 0.8,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildNoEntry() {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
      alignment: Alignment.center,
      child: Container(width: size * 0.7, height: size * 0.18, color: Colors.white),
    );
  }
  
  Widget _buildClosedRoad() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        color: Colors.white,
        border: Border.all(color: Colors.red, width: size * 0.15),
      ),
    );
  }

  Widget _buildNoParking(String l) {
    bool isStopAndPark = l.contains('dừng, đỗ');
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue[800],
            border: Border.all(color: Colors.red, width: size * 0.12),
          ),
        ),
        Transform.rotate(
          angle: -0.785398,
          child: Container(width: size * 0.1, height: size * 0.8, color: Colors.red),
        ),
        if (isStopAndPark)
          Transform.rotate(
            angle: 0.785398,
            child: Container(width: size * 0.1, height: size * 0.8, color: Colors.red),
          ),
      ],
    );
  }

  Widget _buildWarningSign(String l) {
    if (l.contains('hầm chui')) {
      return CustomPaint(
        size: Size(size, size),
        painter: _TrianglePainter(),
        child: CustomPaint(
          size: Size(size, size),
          painter: _TunnelPainter(),
        ),
      );
    }
    
    if (l.contains('tín hiệu đèn')) {
      return CustomPaint(
        size: Size(size, size),
        painter: _TrianglePainter(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(top: size * 0.18),
              child: Container(
                width: size * 0.18,
                height: size * 0.42,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(size * 0.04),
                ),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(width: size * 0.08, height: size * 0.08, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red)),
                    Container(width: size * 0.08, height: size * 0.08, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.amber)),
                    Container(width: size * 0.08, height: size * 0.08, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (l.contains('không bằng phẳng')) {
      return CustomPaint(
        size: Size(size, size),
        painter: _TrianglePainter(),
        child: CustomPaint(
          size: Size(size, size),
          painter: _BumpyRoadPainter(),
        ),
      );
    }

    if (l.contains('đi chậm')) {
      return CustomPaint(
        size: Size(size, size),
        painter: _TrianglePainter(),
        child: SizedBox(
          width: size,
          height: size,
          child: Align(
            alignment: const Alignment(0, 0.45),
            child: Text(
              'CHẬM',
              style: TextStyle(
                color: Colors.black,
                fontSize: size * 0.18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
      );
    }

    IconData iconData = Icons.warning_amber_rounded; // Default
    if (l.contains('người đi bộ')) iconData = Icons.directions_walk;
    else if (l.contains('trẻ em')) iconData = Icons.directions_run; // Children crossing sign
    else if (l.contains('công trình')) iconData = Icons.construction;
    else if (l.contains('giao nhau')) iconData = Icons.close;
    else if (l.contains('trơn')) iconData = Icons.waves;
    else if (l.contains('ngoặt')) iconData = Icons.turn_right;
    else if (l.contains('đường đôi')) iconData = Icons.merge_type;
    else if (l.contains('hẹp')) iconData = Icons.compress;

    // The triangle's visual center (centroid) is at ~58% from top.
    // Icon is placed so its center aligns with the triangle centroid.
    return CustomPaint(
      size: Size(size, size),
      painter: _TrianglePainter(),
      child: SizedBox(
        width: size,
        height: size,
        child: Align(
          alignment: const Alignment(0, 0.35), // Slightly below center = triangle centroid
          child: Icon(iconData, size: size * 0.38, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildMaxSpeedSign(String l) {
    final match = RegExp(r'\d+').firstMatch(l);
    final speed = match != null ? match.group(0) : '50';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.red, width: size * 0.12),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            speed!,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMinSpeedSign(String l) {
    final match = RegExp(r'\d+').firstMatch(l);
    final speed = match != null ? match.group(0) : '30';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        color: Colors.blue[700],
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            speed!,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndRestrictionSign(String l) {
    final match = RegExp(r'\d+').firstMatch(l);
    final String speed = match?.group(0) ?? '';
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: Colors.black, width: size * 0.05),
          ),
          alignment: Alignment.center,
          child: speed.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      speed,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w900,
                        fontSize: size * 0.45,
                      ),
                    ),
                  ),
                )
              : const SizedBox(),
        ),
        // Diagonal lines
        ...List.generate(4, (index) {
          return Transform.rotate(
            angle: -0.785398, // -45 deg
            child: Container(
              margin: EdgeInsets.only(left: index * 6.0 - 9), // spacing them out
              width: size * 0.04,
              height: size * 0.8,
              color: Colors.black87,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMandatorySign(String l) {
    IconData iconData = Icons.arrow_upward;
    if (l.contains('rẽ phải')) iconData = Icons.turn_right;
    else if (l.contains('rẽ trái')) iconData = Icons.turn_left;
    else if (l.contains('vòng xuyến')) iconData = Icons.sync;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue[700]),
      alignment: Alignment.center,
      child: Icon(iconData, color: Colors.white, size: size * 0.6),
    );
  }

  Widget _buildStopSign() {
    return CustomPaint(
      size: Size(size, size),
      painter: _OctagonPainter(),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Text(
          'STOP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.25),
        ),
      ),
    );
  }

  Widget _buildPrioritySign(String l) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: 0.785398, // 45 degrees
          child: Container(
            width: size * 0.75,
            height: size * 0.75,
            decoration: BoxDecoration(
              color: Colors.amber,
              border: Border.all(color: Colors.white, width: size * 0.08),
            ),
          ),
        ),
        if (l.contains('kết thúc'))
          Transform.rotate(
            angle: -0.785398,
            child: Container(
              width: size * 0.1,
              height: size * 1.1,
              color: Colors.black87,
            ),
          ),
      ],
    );
  }

  Widget _buildCitySign(String l) {
    return Container(
      width: size,
      height: size * 0.7,
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.location_city, color: Colors.white, size: size * 0.5),
          if (l.contains('ngoài'))
            Transform.rotate(
              angle: 0.5,
              child: Container(width: size * 0.8, height: size * 0.1, color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.traffic, color: Colors.white, size: size * 0.5),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15
      ..strokeJoin = StrokeJoin.round;

    final double w = size.width;
    final double h = size.height;

    final path = Path()
      ..moveTo(w / 2, h * 0.1) // Top vertex
      ..lineTo(w * 0.9, h * 0.9) // Bottom right
      ..lineTo(w * 0.1, h * 0.9) // Bottom left
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OctagonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeJoin = StrokeJoin.miter;

    final double w = size.width;
    final double h = size.height;
    final double cut = w * 0.29; // approximate for regular octagon

    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(w - cut, 0)
      ..lineTo(w, cut)
      ..lineTo(w, h - cut)
      ..lineTo(w - cut, h)
      ..lineTo(cut, h)
      ..lineTo(0, h - cut)
      ..lineTo(0, cut)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeightLimitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final w = size.width;
    final h = size.height;
    
    // Top triangle pointing down
    final topPath = Path()
      ..moveTo(w / 2, h * 0.32)
      ..lineTo(w / 2 - w * 0.08, h * 0.22)
      ..lineTo(w / 2 + w * 0.08, h * 0.22)
      ..close();
      
    // Bottom triangle pointing up
    final bottomPath = Path()
      ..moveTo(w / 2, h * 0.68)
      ..lineTo(w / 2 - w * 0.08, h * 0.78)
      ..lineTo(w / 2 + w * 0.08, h * 0.78)
      ..close();
      
    canvas.drawPath(topPath, paint);
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TunnelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
      
    final w = size.width;
    final h = size.height;
    
    // Draw an arch representing a tunnel opening
    final path = Path()
      ..moveTo(w * 0.35, h * 0.78)
      ..lineTo(w * 0.35, h * 0.58)
      ..quadraticBezierTo(w * 0.5, h * 0.40, w * 0.65, h * 0.58)
      ..lineTo(w * 0.65, h * 0.78)
      ..lineTo(w * 0.58, h * 0.78)
      ..lineTo(w * 0.58, h * 0.60)
      ..quadraticBezierTo(w * 0.5, h * 0.50, w * 0.42, h * 0.60)
      ..lineTo(w * 0.42, h * 0.78)
      ..close();
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BumpyRoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
      
    final w = size.width;
    final h = size.height;
    
    // Draw two bumps
    final path = Path()
      ..moveTo(w * 0.28, h * 0.72)
      ..quadraticBezierTo(w * 0.36, h * 0.56, w * 0.44, h * 0.72)
      ..quadraticBezierTo(w * 0.52, h * 0.56, w * 0.60, h * 0.72)
      ..lineTo(w * 0.60, h * 0.75)
      ..lineTo(w * 0.28, h * 0.75)
      ..close();
      
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
