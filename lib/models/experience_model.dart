class ExperienceModel {
  final int exp;
  final String rank;
  final int star; // 1-9
  final String phase; // sơ, trung, hậu (chỉ cho Đấu Thánh)

  ExperienceModel({
    required this.exp,
    required this.rank,
    required this.star,
    this.phase = '',
  });

  factory ExperienceModel.fromExp(int exp) {
    // Tính toán rank dựa trên exp
    final result = _calculateRank(exp);
    return ExperienceModel(
      exp: exp,
      rank: result['rank'],
      star: result['star'],
      phase: result['phase'],
    );
  }

  static Map<String, dynamic> _calculateRank(int exp) {
    // Đấu Giả: 0-900 (100 exp/đoạn)
    if (exp < 900) {
      return {
        'rank': 'Đấu Giả',
        'star': (exp ~/ 100) + 1,
        'phase': '',
      };
    }
    
    // Đấu Sư: 900-1800 (100 exp/tinh)
    if (exp < 1800) {
      return {
        'rank': 'Đấu Sư',
        'star': ((exp - 900) ~/ 100) + 1,
        'phase': '',
      };
    }
    
    // Đại Đấu Sư: 1800-2700
    if (exp < 2700) {
      return {
        'rank': 'Đại Đấu Sư',
        'star': ((exp - 1800) ~/ 100) + 1,
        'phase': '',
      };
    }
    
    // Đấu Linh: 2700-3600
    if (exp < 3600) {
      return {
        'rank': 'Đấu Linh',
        'star': ((exp - 2700) ~/ 100) + 1,
        'phase': '',
      };
    }
    
    // Đấu Vương: 3600-4500
    if (exp < 4500) {
      return {
        'rank': 'Đấu Vương',
        'star': ((exp - 3600) ~/ 100) + 1,
        'phase': '',
      };
    }
    
    // Đấu Hoàng: 4500-5400
    if (exp < 5400) {
      return {
        'rank': 'Đấu Hoàng',
        'star': ((exp - 4500) ~/ 100) + 1,
        'phase': '',
      };
    }
    
    // Đấu Tông: 5400-6300
    if (exp < 6300) {
      return {
        'rank': 'Đấu Tông',
        'star': ((exp - 5400) ~/ 100) + 1,
        'phase': '',
      };
    }
    
    // Đấu Tôn: 6300-7200
    if (exp < 7200) {
      return {
        'rank': 'Đấu Tôn',
        'star': ((exp - 6300) ~/ 100) + 1,
        'phase': '',
      };
    }
    
    // Đấu Thánh: 7200-9900 (300 exp/tinh, mỗi tinh có 3 kỳ)
    if (exp < 9900) {
      final totalStarExp = exp - 7200;
      final star = (totalStarExp ~/ 300) + 1;
      final phaseExp = totalStarExp % 300;
      String phase = 'Sơ kỳ';
      if (phaseExp >= 200) {
        phase = 'Hậu kỳ';
      } else if (phaseExp >= 100) {
        phase = 'Trung kỳ';
      }
      
      return {
        'rank': 'Đấu Thánh',
        'star': star,
        'phase': phase,
      };
    }
    
    // Đấu Đế: 9900+
    return {
      'rank': 'Đấu Đế',
      'star': 0,
      'phase': '',
    };
  }

  String get displayRank {
    if (rank == 'Đấu Đế') {
      return 'Đấu Đế';
    }
    
    if (rank == 'Đấu Giả') {
      return '$rank $star đoạn';
    }
    
    if (rank == 'Đấu Thánh') {
      return '$rank $star tinh $phase';
    }
    
    return '$rank $star tinh';
  }

  // Exp cần để lên rank tiếp theo
  int get expToNextRank {
    if (rank == 'Đấu Đế') return 0;
    
    final nextLevelExp = _getNextLevelExp();
    return nextLevelExp - exp;
  }

  int _getNextLevelExp() {
    if (rank == 'Đấu Giả') return 900;
    if (rank == 'Đấu Sư') return 1800;
    if (rank == 'Đại Đấu Sư') return 2700;
    if (rank == 'Đấu Linh') return 3600;
    if (rank == 'Đấu Vương') return 4500;
    if (rank == 'Đấu Hoàng') return 5400;
    if (rank == 'Đấu Tông') return 6300;
    if (rank == 'Đấu Tôn') return 7200;
    if (rank == 'Đấu Thánh') return 9900;
    return 10000; // Đấu Đế
  }

  Map<String, dynamic> toMap() {
    return {
      'exp': exp,
      'rank': rank,
      'star': star,
      'phase': phase,
    };
  }
}
