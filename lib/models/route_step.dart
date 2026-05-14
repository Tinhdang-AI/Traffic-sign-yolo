import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Representa uma instrução de virada específica na rota
class RouteStep {
  /// Distância em metros até o próximo passo
  final int distanceMeters;
  final String distanceText;

  /// Tempo em segundos para completar este passo
  final int durationSeconds;

  /// Tipo de manobra: turn, merge, depart, arrive, fork, etc.
  final String maneuver;

  /// Direção da manobra: sharp right, slight left, straight, etc.
  final String? direction;

  /// Ângulo da manobra em graus (0-180: direita, 180-360: esquerda)
  final double? bearing;

  /// Nome da rua/avenida
  final String name;

  /// Instrução completa em formato legível
  final String instruction;

  /// Coordenadas do início do passo
  final LatLng location;

  RouteStep({
    required this.distanceMeters,
    required this.distanceText,
    required this.durationSeconds,
    required this.maneuver,
    this.direction,
    this.bearing,
    required this.name,
    required this.instruction,
    required this.location,
  });

  /// Converte manobra em ícone/emoji navegação
  String get directionEmoji {
    switch (maneuver) {
      case 'turn':
        if (direction?.contains('right') ?? false) return '🔄→';
        if (direction?.contains('left') ?? false) return '↩️←';
        return '↑';
      case 'slight':
        if (direction?.contains('right') ?? false) return '→';
        if (direction?.contains('left') ?? false) return '←';
        return '↑';
      case 'sharp':
        if (direction?.contains('right') ?? false) return '⤴️';
        if (direction?.contains('left') ?? false) return '⤴️';
        return '↑';
      case 'straight':
        return '↑';
      case 'u-turn':
        return '🔁';
      case 'merge':
        return '➡️';
      case 'fork':
        return '↗️';
      case 'arrive':
        return '🎯';
      default:
        return '→';
    }
  }

  /// Instrução em vietnamita com ícone
  String get vietnameseInstruction {
    String prefix = directionEmoji;

    switch (maneuver) {
      case 'turn':
        if (direction?.contains('right') ?? false) {
          return '$prefix Rẽ phải';
        }
        if (direction?.contains('left') ?? false) {
          return '$prefix Rẽ trái';
        }
        return '$prefix Đi thẳng';

      case 'slight':
        if (direction?.contains('right') ?? false) {
          return '$prefix Chếch phải';
        }
        if (direction?.contains('left') ?? false) {
          return '$prefix Chếch trái';
        }
        return '$prefix Đi thẳng';

      case 'sharp':
        if (direction?.contains('right') ?? false) {
          return '$prefix Rẽ gấp phải';
        }
        if (direction?.contains('left') ?? false) {
          return '$prefix Rẽ gấp trái';
        }
        return '$prefix Quay đầu';

      case 'u-turn':
        return '$prefix Quay đầu';

      case 'merge':
        return '$prefix Nhập làn';

      case 'fork':
        return '$prefix Rẽ tại ngã tư';

      case 'arrive':
        return '$prefix Đã đến điểm đích';

      case 'depart':
        return '$prefix Khởi hành';

      case 'straight':
        return '$prefix Đi thẳng';

      default:
        return '$prefix ${maneuver}';
    }
  }

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    final distanceMeters = (json['distance'] as num?)?.toInt() ?? 0;
    final durationSeconds = (json['duration'] as num?)?.toInt() ?? 0;
    final maneuver = json['maneuver']?['type'] ?? 'straight';
    final direction = json['maneuver']?['modifier'];
    final bearing = (json['maneuver']?['bearing_after'] as num?)?.toDouble();

    // Get street name from destinations or name field
    final List<dynamic>? intersections = json['intersections'];
    final String name =
        json['name'] ??
        (intersections?.isNotEmpty == true
            ? intersections!.first['location']?.toString() ?? 'Rua desconhecida'
            : 'Rua desconhecida');

    final List<dynamic>? coords = json['geometry']?['coordinates'];
    final LatLng location = coords != null && coords.isNotEmpty
        ? LatLng(
            (coords.first[1] as num).toDouble(),
            (coords.first[0] as num).toDouble(),
          )
        : const LatLng(0, 0);

    return RouteStep(
      distanceMeters: distanceMeters,
      distanceText: distanceMeters >= 1000
          ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
          : '${distanceMeters} m',
      durationSeconds: durationSeconds,
      maneuver: maneuver,
      direction: direction,
      bearing: bearing,
      name: name,
      instruction: '',
      location: location,
    );
  }
}
