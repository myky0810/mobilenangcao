import '../models/car_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CarDataService {
  static final CarDataService _instance = CarDataService._internal();
  factory CarDataService() => _instance;
  CarDataService._internal();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static bool _initialized = false;

  // Centralized car data store
  static final Map<String, Map<String, dynamic>> _defaultCarsDatabase = {
    // Mercedes Cars
    'mercedes_amg_gt_coupe_2024': {
      'id': 'mercedes_amg_gt_coupe_2024',
      'name': 'Mercedes-Benz AMG GT Coupe 2024',
      'brand': 'Mercedes',
      'price': '8.500.000.000đ',
      'priceNote': 'Lăn bánh từ 9.2 tỷ',
      'image': 'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-00cab4cac69d4468527a0bddd73df086de.jpg',
      'rating': 9.5,
      'reviewCount': 210,
      'isNew': true,
      'description': 'Mercedes-Benz AMG GT Coupe 2024 là siêu xe thể thao đỉnh cao với động cơ V8 twin-turbo 4.0L, sản sinh 577 mã lực. Thiết kế thuần thể thao với nội thất AMG Performance cao cấp, hệ thống treo thích ứng và chế độ lái đa dạng giúp xe chinh phục mọi cung đường.',
      'gallery': [
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-00cab4cac69d4468527a0bddd73df086de.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-0af94a1f278f934636c462f62623fc4b76.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-421ec0ae85aedddd995507af718580eb0f.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-69b33067617647b278192eaa4d4cf713cb.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-8bd412930d690a0d314d4a59497b92606a.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-Rear.91ad5a3f.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-Side_Profile.91ad5a3f.jpg',
      ],
    },
    'mercedes_g63_amg_2025': {
      'id': 'mercedes_g63_amg_2025',
      'name': 'Mercedes-Benz G63 AMG 2025',
      'brand': 'Mercedes',
      'price': '11.900.000.000đ',
      'priceNote': 'Lăn bánh từ 13 tỷ',
      'image': 'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-038bcbee2f3dd71d41f1185ec519c69811.jpg',
      'rating': 9.8,
      'reviewCount': 156,
      'isNew': true,
      'description': 'Mercedes-Benz G63 AMG 2025 - Huyền thoại SUV hiệu năng cao với thiết kế hộp cơ bắp, động cơ V8 Biturbo 4.0L 585 mã lực, nội thất Nappa cao cấp và khả năng off-road đỉnh cao.',
      'gallery': [
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-038bcbee2f3dd71d41f1185ec519c69811.jpg',
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-1a2b3c4d5e6f7890123456789abcdef.jpg',
        'assets/images/products/Mercedes-Benz-G63_AMG-2025-1280-fedcba9876543210987654321fedcba.jpg',
      ],
    },

    // BMW Cars
    'bmw_3_series_2019': {
      'id': 'bmw_3_series_2019',
      'name': 'BMW 3 Series 2019',
      'brand': 'BMW',
      'price': '1.899.000.000đ',
      'priceNote': 'Lăn bánh từ 2.1 tỷ',
      'image': 'assets/images/products/BMW-3-Series-2019-1280-199cd3c9a9e4186bdafdb6442254df99de.jpg',
      'rating': 8.5,
      'reviewCount': 128,
      'isNew': true,
      'description': 'BMW 3 Series 2019 là sedan hạng sang mang ADN thể thao BMW đặc trưng. Động cơ TwinPower Turbo, hệ thống treo thích ứng và cảm giác lái chính xác cùng nội thất cao cấp tạo nên trải nghiệm lý tưởng cho người yêu xe.',
      'gallery': [
        'assets/images/products/BMW-3-Series-2019-1280-199cd3c9a9e4186bdafdb6442254df99de.jpg',
        'assets/images/products/BMW-3-Series-2019-1280-262e22c0f5ff5d0bb5e9edb3f2158fb2b5.jpg',
        'assets/images/products/BMW-3-Series-2019-1280-910360cae38e49661529df4963594c9f1a.jpg',
        'assets/images/products/BMW-3-Series-2019-1280-c7d9ede0564a4798c28f1cfee053f7ba1b.jpg',
        'assets/images/products/BMW-3-Series-2019-1280-f337b44e6f1581d4771a85e301ef1d9f9b.jpg',
        'assets/images/products/BMW-3-Series-2019-Rear_Three-Quarter.2693abe9.jpg',
      ],
    },
    'bmw_x7_2023': {
      'id': 'bmw_x7_2023',
      'name': 'BMW X7 2023',
      'brand': 'BMW',
      'price': '7.799.000.000đ',
      'priceNote': 'Lăn bánh từ 8.5 tỷ',
      'image': 'assets/images/products/BMW-X7-2023-1280-1980c2431b01e69530f98bf3202efb03d2.jpg',
      'rating': 9.2,
      'reviewCount': 88,
      'isNew': true,
      'description': 'BMW X7 2023 – SUV đỉnh cao hạng sang 6/7 chỗ. Mặt ca-lăng đôi lớn và táo bạo, nội thất rộng rãi sang trọng với 3 hàng ghế thoải mái, hệ thống giải trí màn hình đôi cong 14.9 inch và đầy đủ công nghệ hỗ trợ lái.',
      'gallery': [
        'assets/images/products/BMW-X7-2023-1280-1980c2431b01e69530f98bf3202efb03d2.jpg',
        'assets/images/products/BMW-X7-2023-1280-297ea50aea9d6f4fb52a4cca5a5718131f.jpg',
        'assets/images/products/BMW-X7-2023-1280-528da416a6f27c502b174cf3c931e7fe73.jpg',
        'assets/images/products/BMW-X7-2023-1280-664e52a5958bfe61899dc501d95ab720bb.jpg',
        'assets/images/products/BMW-X7-2023-1280-9263bf2a78ef49c7e8752a9d49d7c571d5.jpg',
        'assets/images/products/BMW-X7-2023-1280-eb0880478b2b938f9ecb766e3902ccd5a7.jpg',
        'assets/images/products/BMW-X7-2023-1280-f06e1865b7babd08a7c8baaae989ebd58b.jpg',
      ],
    },

    // Tesla Cars
    'tesla_cybertruck_2025': {
      'id': 'tesla_cybertruck_2025',
      'name': 'Tesla Cybertruck 2025',
      'brand': 'Tesla',
      'price': '2.091.538.525đ',
      'priceNote': 'Lăn bánh từ 2.3 tỷ',
      'image': 'assets/images/products/Tesla-Cybertruck-2025-1280-aba810131368e11e171f4658a02a79d3f2.jpg',
      'rating': 9.0,
      'reviewCount': 245,
      'isNew': true,
      'description': 'Tesla Cybertruck 2025 - Pickup truck điện tương lai với thân xe thép không gỉ, khung gầm siêu cứng, phạm vi hoạt động hơn 800km và khả năng tăng tốc 0-100km/h dưới 3 giây.',
      'gallery': [
        'assets/images/products/Tesla-Cybertruck-2025-1280-aba810131368e11e171f4658a02a79d3f2.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-16e1b7f3835967587c752ccbc071af69c5.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-4c154b2d57ac41a915b7ad60624ed73dc1.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-7ca3be8dc288bd177f33cdb0d03ecaa027.jpg',
      ],
    },

    // Toyota Cars
    'toyota_camry_2021': {
      'id': 'toyota_camry_2021',
      'name': 'Toyota Camry 2021',
      'brand': 'Toyota',
      'price': '1.320.000.000đ',
      'priceNote': 'Lăn bánh từ 1.5 tỷ',
      'image': 'assets/images/products/Toyota-Camry-2021-1280-064ad2cc20466b8915c514999074418bde.jpg',
      'rating': 8.5,
      'reviewCount': 155,
      'isNew': true,
      'description': 'Toyota Camry 2021 nổi tiếng với sự bền bỉ, vận hành êm và cách âm xuất sắc. Thiết kế Dynamic Force Engine 2.5L, nội thất rộng rãi tiện nghi đầy đủ, hệ thống an toàn Toyota Safety Sense. Lựa chọn lý tưởng cho gia đình và doanh nhân.',
      'gallery': [
        'assets/images/products/Toyota-Camry-2021-1280-064ad2cc20466b8915c514999074418bde.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-32243d6b4b7278beb0aab08ce0d373d49f.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-7103cc843047ebe56d6a7d6fb095c35419.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-8671f0b512ac1f70c2a1bc4c60c8d28092.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-8d5933ff56455450044ab1183050f61fae.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-cc5fc213cb86e36bea6be48360ab721695.jpg',
      ],
    },
    'toyota_land_cruiser_2021': {
      'id': 'toyota_land_cruiser_2021',
      'name': 'Toyota Land Cruiser 2021',
      'brand': 'Toyota',
      'price': '4.030.000.000đ',
      'priceNote': 'Lăn bánh từ 4.5 tỷ',
      'image': 'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-25e61cd74c005244b365b541306e5e4e7d.jpg',
      'rating': 9.1,
      'reviewCount': 189,
      'isNew': false,
      'description': 'Toyota Land Cruiser 2021 - SUV huyền thoại với khả năng off-road vượt trội, động cơ V8 4.5L mạnh mẽ, nội thất sang trọng và độ bền bỉ legendary. Lựa chọn hoàn hảo cho những chuyến phiêu lưu.',
      'gallery': [
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-25e61cd74c005244b365b541306e5e4e7d.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-4efc18483995a822f3ece39367d5d155ed.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-58ff0f9258d235b970aa7e53956b659206.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-f3049447d164609d97e40ac527c2d83b53.jpg',
      ],
    },

    // Volvo Cars
    'volvo_xc90_2023': {
      'id': 'volvo_xc90_2023',
      'name': 'Volvo XC90 2023',
      'brand': 'Volvo',
      'price': '3.850.000.000đ',
      'priceNote': 'Lăn bánh từ 4.2 tỷ',
      'image': 'assets/images/products/Volvo-XC90-2023-1280-1a2b3c4d5e6f7890.jpg',
      'rating': 8.8,
      'reviewCount': 142,
      'isNew': false,
      'description': 'Volvo XC90 2023 - SUV 7 chỗ an toàn nhất thế giới với thiết kế Scandinavian tối giản, nội thất Nappa leather, hệ thống an toàn IntelliSafe và động cơ hybrid tiết kiệm.',
      'gallery': [
        'assets/images/products/Volvo-XC90-2023-1280-1a2b3c4d5e6f7890.jpg',
        'assets/images/products/Volvo-XC90-2023-1280-2b3c4d5e6f789012.jpg',
        'assets/images/products/Volvo-XC90-2023-1280-3c4d5e6f78901234.jpg',
      ],
    },

    // Mazda Cars
    'mazda_cx5_2023': {
      'id': 'mazda_cx5_2023',
      'name': 'Mazda CX-5 2023',
      'brand': 'Mazda',
      'price': '1.099.000.000đ',
      'priceNote': 'Lăn bánh từ 1.2 tỷ',
      'image': 'assets/images/products/Mazda-CX5-2023-1280-1a2b3c4d5e6f7890.jpg',
      'rating': 8.3,
      'reviewCount': 198,
      'isNew': false,
      'description': 'Mazda CX-5 2023 - SUV compact với thiết kế KODO đẹp mắt, nội thất cao cấp, động cơ Skyactiv-G tiết kiệm và công nghệ an toàn i-Activsense.',
      'gallery': [
        'assets/images/products/Mazda-CX5-2023-1280-1a2b3c4d5e6f7890.jpg',
        'assets/images/products/Mazda-CX5-2023-1280-2b3c4d5e6f789012.jpg',
        'assets/images/products/Mazda-CX5-2023-1280-3c4d5e6f78901234.jpg',
      ],
    },

    // Hyundai Cars
    'hyundai_tucson_2023': {
      'id': 'hyundai_tucson_2023',
      'name': 'Hyundai Tucson 2023',
      'brand': 'Hyundai',
      'price': '990.000.000đ',
      'priceNote': 'Lăn bánh từ 1.1 tỷ',
      'image': 'assets/images/products/Hyundai-Tucson-2023-1280-1a2b3c4d5e6f7890.jpg',
      'rating': 8.1,
      'reviewCount': 167,
      'isNew': false,
      'description': 'Hyundai Tucson 2023 - SUV C-segment với thiết kế Parametric Dynamics hiện đại, nội thất thông minh, nhiều tùy chọn động cơ và công nghệ an toàn Hyundai SmartSense.',
      'gallery': [
        'assets/images/products/Hyundai-Tucson-2023-1280-1a2b3c4d5e6f7890.jpg',
        'assets/images/products/Hyundai-Tucson-2023-1280-2b3c4d5e6f789012.jpg',
        'assets/images/products/Hyundai-Tucson-2023-1280-3c4d5e6f78901234.jpg',
      ],
    },
  };

  static Map<String, Map<String, dynamic>> _carsDatabase =
      Map<String, Map<String, dynamic>>.from(_defaultCarsDatabase);

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final snapshot = await _db.collection('products').get();

      if (snapshot.docs.isEmpty) {
        await _seedProductsToFirestore();
      } else {
        _carsDatabase = {
          for (final doc in snapshot.docs)
            doc.id: _normalizeCarMap(doc.id, doc.data()),
        };
      }
    } catch (_) {
      // Keep local defaults when Firestore is unavailable.
      _carsDatabase = Map<String, Map<String, dynamic>>.from(_defaultCarsDatabase);
    }

    _initialized = true;
  }

  Future<void> _seedProductsToFirestore() async {
    final batch = _db.batch();

    for (final entry in _defaultCarsDatabase.entries) {
      final ref = _db.collection('products').doc(entry.key);
      batch.set(ref, {
        ...entry.value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
    _carsDatabase = Map<String, Map<String, dynamic>>.from(_defaultCarsDatabase);
  }

  Map<String, dynamic> _normalizeCarMap(String id, Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    map['id'] = (map['id'] ?? id).toString();
    map['gallery'] = ((map['gallery'] as List?) ??
            ((map['images'] as List?) ?? const <dynamic>[]))
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();

    map['name'] = (map['name'] ?? '').toString();
    map['brand'] = (map['brand'] ?? '').toString();
    map['price'] = (map['price'] ?? '').toString();
    map['priceNote'] = (map['priceNote'] ?? 'Liên hệ').toString();
    map['image'] = (map['image'] ?? '').toString();
    map['description'] = (map['description'] ?? '').toString();
    map['rating'] = (map['rating'] is num)
        ? (map['rating'] as num).toDouble()
        : double.tryParse((map['rating'] ?? '').toString()) ?? 4.5;
    map['reviewCount'] = (map['reviewCount'] is num)
        ? (map['reviewCount'] as num).toInt()
        : int.tryParse((map['reviewCount'] ?? '').toString()) ?? 0;
    map['isNew'] = map['isNew'] == true;

    return map;
  }

  // Get all cars
  List<Map<String, dynamic>> getAllCars() {
    return _carsDatabase.values.toList();
  }

  // Get cars by brand
  List<Map<String, dynamic>> getCarsByBrand(String brand) {
    return _carsDatabase.values
        .where((car) => car['brand'].toString().toLowerCase() == brand.toLowerCase())
        .toList();
  }

  // Get car by ID
  Map<String, dynamic>? getCarById(String id) {
    return _carsDatabase[id];
  }

  // Get all available brands
  List<String> getAllBrands() {
    final brands = _carsDatabase.values
        .map((car) => car['brand'] as String)
        .toSet()
        .toList();
    brands.sort();
    return brands;
  }

  // Get featured cars (for home screen)
  List<Map<String, dynamic>> getFeaturedCars({int limit = 4}) {
    final featuredCars = _carsDatabase.values.toList()
      ..sort((a, b) {
        // Sort by rating first, then by review count
        final ratingCompare = (b['rating'] as num).compareTo(a['rating'] as num);
        if (ratingCompare != 0) return ratingCompare;
        return (b['reviewCount'] as int).compareTo(a['reviewCount'] as int);
      });
    
    return featuredCars.take(limit).toList();
  }

  // Get new cars
  List<Map<String, dynamic>> getNewCars({int limit = 6}) {
    final newCars = _carsDatabase.values
        .where((car) => car['isNew'] == true)
        .toList()
      ..sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
    
    return newCars.take(limit).toList();
  }

  // Search cars by name or brand
  List<Map<String, dynamic>> searchCars(String query) {
    if (query.isEmpty) return getAllCars();
    
    final lowerQuery = query.toLowerCase();
    return _carsDatabase.values.where((car) {
      final name = (car['name'] as String).toLowerCase();
      final brand = (car['brand'] as String).toLowerCase();
      return name.contains(lowerQuery) || brand.contains(lowerQuery);
    }).toList();
  }

  // Add new car to database
  void addCar(Map<String, dynamic> car) {
    final id = car['id'] as String;
    _carsDatabase[id] = Map<String, dynamic>.from(car);
  }

  // Update existing car
  void updateCar(String id, Map<String, dynamic> updates) {
    if (_carsDatabase.containsKey(id)) {
      _carsDatabase[id]!.addAll(updates);
    }
  }

  // Remove car from database
  void removeCar(String id) {
    _carsDatabase.remove(id);
  }

  // Convert car data to CarDetailData
  CarDetailData toCarDetailData(Map<String, dynamic> car, {String? phoneNumber}) {
    return CarDetailData(
      id: car['id'] as String,
      name: car['name'] as String,
      brand: car['brand'] as String,
      image: car['image'] as String,
      price: car['price'] as String,
      description: car['description'] as String? ?? '',
      images: (car['gallery'] as List<String>?) ?? [car['image'] as String],
      rating: (car['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (car['reviewCount'] as int?) ?? 50,
      isNew: car['isNew'] as bool? ?? false,
      phoneNumber: phoneNumber,
    );
  }
}
