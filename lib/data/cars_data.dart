import 'package:doan_cuoiki/models/car_detail.dart';

/// File dữ liệu xe tập trung - sử dụng chung cho toàn app
/// Khi cập nhật ở đây sẽ tự động cập nhật toàn app

class CarBrandInfo {
  final String name;
  final String assetPath;

  CarBrandInfo({required this.name, required this.assetPath});
}

class CarsData {
  /// Danh sách tất cả hãng xe trong hệ thống
  static List<CarBrandInfo> brands = [
    CarBrandInfo(
      name: 'Mercedes',
      assetPath: 'assets/images/icons8-mercedes-benz-48.png',
    ),
    CarBrandInfo(
      name: 'Tesla',
      assetPath: 'assets/images/icons8-tesla-48.png',
    ),
    CarBrandInfo(
      name: 'BMW',
      assetPath: 'assets/images/icons8-bmw-48.png',
    ),
    CarBrandInfo(
      name: 'Toyota',
      assetPath: 'assets/images/icons8-toyota-48.png',
    ),
    CarBrandInfo(
      name: 'Volvo',
      assetPath: 'assets/images/icons8-volvo-100.png',
    ),
    CarBrandInfo(
      name: 'Mazda',
      assetPath: 'assets/images/icons8-mazda-48.png',
    ),
    CarBrandInfo(
      name: 'Hyundai',
      assetPath: 'assets/images/icons8-hyundai-48.png',
    ),
  ];

  /// Danh sách tất cả xe trong hệ thống (mỗi xe chỉ có 1 bản)
  static const List<CarDetailData> allCars = [
    CarDetailData(
      id: 'mercedes_amg_gt_coupe_2024',
      name: 'Mercedes-Benz AMG GT Coupe 2024',
      brand: 'Mercedes',
      price: '8.500.000.000₫',
      description: 'Xe coupe thể thao sang trọng từ Mercedes-Benz.',
      image:
          'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-00cab4cac69d4468527a0bddd73df086de.jpg',
      images: [
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-00cab4cac69d4468527a0bddd73df086de.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-2de29e9b9a86483c11f3779bac10cd5929.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-3c0a7e2e90aae7e1d15736519f0b3cf3a5.jpg',
        'assets/images/products/Mercedes-Benz-AMG_GT_Coupe-2024-1280-a7b02c4db5d04a1bd5dbf1d8b30e87b024.jpg',
      ],
      rating: 4.8,
      reviewCount: 128,
      isNew: true,
      category: 'Coupe',
      seats: '2-4 chỗ',
      fuelType: 'Xăng',
      driveType: 'RWD',
      transmission: 'Số tự động',
      horsepower: 630,
      engine: 'V8 Twin-Turbo 4.0L',
      purpose: 'Thể thao',
    ),
    CarDetailData(
      id: 'bmw_x7_2023',
      name: 'BMW X7 2023',
      brand: 'BMW',
      price: '7.799.000.000₫',
      description: 'SUV cỡ lớn hạng sang với 3 hàng ghế.',
      image:
          'assets/images/products/BMW-X7-2023-1280-1980c2431b01e69530f98bf3202efb03d2.jpg',
      images: [
        'assets/images/products/BMW-X7-2023-1280-1980c2431b01e69530f98bf3202efb03d2.jpg',
        'assets/images/products/BMW-X7-2023-1280-297ea50aea9d6f4fb52a4cca5a5718131f.jpg',
        'assets/images/products/BMW-X7-2023-1280-528da416a6f27c502b174cf3c931e7fe73.jpg',
        'assets/images/products/BMW-X7-2023-1280-664e52a5958bfe61899dc501d95ab720bb.jpg',
        'assets/images/products/BMW-X7-2023-1280-9263bf2a78ef49c7e8752a9d49d7c571d5.jpg',
      ],
      rating: 4.9,
      reviewCount: 94,
      isNew: true,
      category: 'SUV',
      seats: '6-7 chỗ',
      fuelType: 'Xăng',
      driveType: 'AWD',
      transmission: 'Số tự động',
      horsepower: 523,
      engine: 'TwinPower Turbo V8 4.4L',
      purpose: 'Gia đình',
    ),
    CarDetailData(
      id: 'tesla_cybertruck_2025',
      name: 'Tesla Cybertruck 2025',
      brand: 'Tesla',
      price: '2.091.538.525₫',
      description: 'Bán tải điện tương lai với thiết kế độc đáo.',
      image:
          'assets/images/products/Tesla-Cybertruck-2025-1280-aba810131368e11e171f4658a02a79d3f2.jpg',
      images: [
        'assets/images/products/Tesla-Cybertruck-2025-1280-aba810131368e11e171f4658a02a79d3f2.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-16e1b7f3835967587c752ccbc071af69c5.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-4c154b2d57ac41a915b7ad60624ed73dc1.jpg',
        'assets/images/products/Tesla-Cybertruck-2025-1280-7ca3be8dc288bd177f33cdb0d03ecaa027.jpg',
      ],
      rating: 4.9,
      reviewCount: 142,
      isNew: true,
      category: 'Bán tải',
      seats: '5 chỗ',
      fuelType: 'Điện',
      driveType: 'AWD',
      transmission: '1 cấp',
      horsepower: 845,
      engine: 'Tri Motor Electric AWD',
      purpose: 'Off-road',
    ),
    CarDetailData(
      id: 'toyota_land_cruiser_2021',
      name: 'Toyota Land Cruiser 2021',
      brand: 'Toyota',
      price: '4.030.000.000₫',
      description: 'SUV địa hình huyền thoại với độ bền cao.',
      image:
          'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-25e61cd74c005244b365b541306e5e4e7d.jpg',
      images: [
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-25e61cd74c005244b365b541306e5e4e7d.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-4efc18483995a822f3ece39367d5d155ed.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-58ff0f9258d235b970aa7e53956b659206.jpg',
        'assets/images/products/Toyota-Land_Cruiser_EU-Version-2021-1280-f3049447d164609d97e40ac527c2d83b53.jpg',
      ],
      rating: 4.9,
      reviewCount: 89,
      isNew: false,
      category: 'SUV',
      seats: '8 chỗ',
      fuelType: 'Dầu',
      driveType: '4WD',
      transmission: 'Số tự động',
      horsepower: 304,
      engine: 'V6 Diesel 3.3L Twin-Turbo',
      purpose: 'Off-road',
    ),
    CarDetailData(
      id: 'bmw_3_series_2019',
      name: 'BMW 3 Series 2019',
      brand: 'BMW',
      price: '1.899.000.000 đ',
      description: 'Sedan thể thao sang trọng của BMW.',
      image:
          'assets/images/products/BMW-3-Series-2019-1280-199cd3c9a9e4186bdafdb6442254df99de.jpg',
      images: [
        'assets/images/products/BMW-3-Series-2019-1280-199cd3c9a9e4186bdafdb6442254df99de.jpg',
        'assets/images/products/BMW-3-Series-2019-1280-262e22c0f5ff5d0bb5e9edb3f2158fb2b5.jpg',
        'assets/images/products/BMW-3-Series-2019-Rear_Three-Quarter.2693abe9.jpg',
      ],
      rating: 4.8,
      reviewCount: 128,
      isNew: true,
      category: 'Sedan',
      seats: '5 chỗ',
      fuelType: 'Xăng',
      driveType: 'RWD',
      transmission: 'Số tự động',
      horsepower: 255,
      engine: 'TwinPower Turbo 2.0L',
      purpose: 'Doanh nhân',
    ),
    CarDetailData(
      id: 'mercedes_glc_coupe_2024',
      name: 'Mercedes-Benz GLC Coupe 2024',
      brand: 'Mercedes',
      price: '3.299.000.000 đ',
      description: 'SUV coupe sang trọng, mềm mại và thể thao.',
      image:
          'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-3d89595d79f2fdc414118a494015c6d489.jpg',
      images: [
        'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-3d89595d79f2fdc414118a494015c6d489.jpg',
        'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-1280-63e36b654c72694284f49bc4a81b901da4.jpg',
        'assets/images/products/Mercedes-Benz-GLC_Coupe-2024-Front.9d58c872.jpg',
      ],
      rating: 4.7,
      reviewCount: 112,
      isNew: true,
      category: 'SUV',
      seats: '5 chỗ',
      fuelType: 'Hybrid',
      driveType: 'AWD',
      transmission: 'Số tự động',
      horsepower: 255,
      engine: 'Mild-Hybrid 2.0L Turbo',
      purpose: 'Doanh nhân',
    ),
    CarDetailData(
      id: 'tesla_model_3_2024',
      name: 'Tesla Model 3 2024',
      brand: 'Tesla',
      price: '1.599.000.000 đ',
      description: 'Sedan điện hiện đại với công nghệ OTA.',
      image:
          'assets/images/products/Tesla-Model_3-2024-1280-3f2af9ab7a564be8488ad85f205963fdf3.jpg',
      images: [
        'assets/images/products/Tesla-Model_3-2024-1280-3f2af9ab7a564be8488ad85f205963fdf3.jpg',
        'assets/images/products/Tesla-Model_3-2024-1280-7020760cdd5c40f8fc3cb613b07644362f.jpg',
        'assets/images/products/Tesla-Model_3-2024-1280-f4e2f306a7b7e7b9b962b3efb0d46167bb.jpg',
      ],
      rating: 4.8,
      reviewCount: 176,
      isNew: true,
      category: 'Sedan',
      seats: '5 chỗ',
      fuelType: 'Điện',
      driveType: 'AWD',
      transmission: '1 cấp',
      horsepower: 498,
      engine: 'Dual Motor Electric',
      purpose: 'Đô thị',
    ),
    CarDetailData(
      id: 'toyota_camry_2021',
      name: 'Toyota Camry 2021',
      brand: 'Toyota',
      price: '1.320.000.000 đ',
      description: 'Sedan bền bỉ, êm ái và phù hợp gia đình.',
      image:
          'assets/images/products/Toyota-Camry-2021-1280-064ad2cc20466b8915c514999074418bde.jpg',
      images: [
        'assets/images/products/Toyota-Camry-2021-1280-064ad2cc20466b8915c514999074418bde.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-32243d6b4b7278beb0aab08ce0d373d49f.jpg',
        'assets/images/products/Toyota-Camry-2021-1280-cc5fc213cb86e36bea6be48360ab721695.jpg',
      ],
      rating: 4.6,
      reviewCount: 203,
      isNew: false,
      category: 'Sedan',
      seats: '5 chỗ',
      fuelType: 'Xăng',
      driveType: 'FWD',
      transmission: 'Số tự động',
      horsepower: 203,
      engine: 'Dynamic Force 2.5L',
      purpose: 'Gia đình',
    ),
    CarDetailData(
      id: 'volvo_xc40_recharge_2023',
      name: 'Volvo XC40 Recharge 2023',
      brand: 'Volvo',
      price: '2.299.000.000 đ',
      description: 'SUV điện Bắc Âu gọn gàng, an toàn và hiện đại.',
      image:
          'assets/images/products/Volvo-XC40_Recharge-2023-1280-20af6e11057d63aefa0b99ee4160b33035.jpg',
      images: [
        'assets/images/products/Volvo-XC40_Recharge-2023-1280-20af6e11057d63aefa0b99ee4160b33035.jpg',
        'assets/images/products/Volvo-XC40_Recharge-2023-1280-a1bc2d0f31a3b46f38358216c1433f3db7.jpg',
        'assets/images/products/Volvo-XC40_Recharge-2023-wallpaper.jpg',
      ],
      rating: 4.7,
      reviewCount: 97,
      isNew: true,
      category: 'SUV',
      seats: '5 chỗ',
      fuelType: 'Điện',
      driveType: 'AWD',
      transmission: '1 cấp',
      horsepower: 408,
      engine: 'Recharge Electric',
      purpose: 'Đô thị',
    ),
    CarDetailData(
      id: 'hyundai_santa_fe_2024',
      name: 'Hyundai Santa Fe 2024',
      brand: 'Hyundai',
      price: '1.329.000.000 đ',
      description:
          'SUV 7 chỗ với thiết kế mạnh mẽ, nội thất rộng rãi và công nghệ an toàn.',
      image: 'assets/images/products/car1.jpg',
      images: [
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
      ],
      rating: 4.7,
      reviewCount: 145,
      isNew: false,
      category: 'SUV',
      seats: '6-7 chỗ',
      fuelType: 'Xăng',
      driveType: 'AWD',
      transmission: 'Số tự động',
      horsepower: 278,
      engine: '2.5L Turbo',
      purpose: 'Gia đình',
    ),
    CarDetailData(
      id: 'hyundai_tucson_2025',
      name: 'Hyundai Tucson 2025',
      brand: 'Hyundai',
      price: '799.000.000 đ',
      description:
          'SUV thế hệ mới với thiết kế táo bạo, công nghệ SmartSense và nội thất cao cấp.',
      image: 'assets/images/products/car2.jpg',
      images: [
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
        'assets/images/products/car1.jpg',
      ],
      rating: 4.6,
      reviewCount: 128,
      isNew: true,
      category: 'SUV',
      seats: '5 chỗ',
      fuelType: 'Xăng',
      driveType: 'AWD',
      transmission: 'Số tự động',
      horsepower: 230,
      engine: '2.5L Turbo',
      purpose: 'Đô thị',
    ),
    CarDetailData(
      id: 'mazda_cx5_2024',
      name: 'Mazda CX-5 2024',
      brand: 'Mazda',
      price: '839.000.000 đ',
      description:
          'SUV thế hệ mới với thiết kế KODO, vận hành thể thao và nội thất sang trọng.',
      image: 'assets/images/products/car1.jpg',
      images: [
        'assets/images/products/car1.jpg',
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
      ],
      rating: 4.8,
      reviewCount: 156,
      isNew: true,
      category: 'SUV',
      seats: '5 chỗ',
      fuelType: 'Xăng',
      driveType: 'AWD',
      transmission: 'Số tự động',
      horsepower: 256,
      engine: '2.5L Skyactiv-G',
      purpose: 'Gia đình',
    ),
    CarDetailData(
      id: 'mazda3_2024',
      name: 'Mazda3 2024',
      brand: 'Mazda',
      price: '669.000.000 đ',
      description:
          'Sedan hạng C với thiết kế thể thao, vận hành linh hoạt và nội thất cao cấp.',
      image: 'assets/images/products/car2.jpg',
      images: [
        'assets/images/products/car2.jpg',
        'assets/images/products/car3.jpg',
        'assets/images/products/car1.jpg',
      ],
      rating: 4.7,
      reviewCount: 123,
      isNew: false,
      category: 'Sedan',
      seats: '5 chỗ',
      fuelType: 'Xăng',
      driveType: 'FWD',
      transmission: 'Số tự động',
      horsepower: 190,
      engine: '2.0L Skyactiv-G',
      purpose: 'Đô thị',
    ),
  ];

  /// Lấy xe theo brand
  static List<CarDetailData> getCarsByBrand(String brand) {
    return allCars.where((car) => car.brand == brand).toList();
  }

  /// Lấy xe mới (isNew = true)
  static List<CarDetailData> getNewCars() {
    return allCars.where((car) => car.isNew).toList();
  }

  /// Lấy xe theo category
  static List<CarDetailData> getCarsByCategory(String category) {
    return allCars.where((car) => car.category == category).toList();
  }

  /// Kiểm tra xe có tồn tại không
  static CarDetailData? findCarById(String id) {
    try {
      return allCars.firstWhere((car) => car.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Lấy danh sách tất cả các category
  static List<String> getAllCategories() {
    return allCars
        .map((car) => car.category)
        .where((category) => category?.isNotEmpty == true)
        .map((category) => category!) // Unwrap non-null
        .toSet()
        .toList()
      ..sort();
  }

  /// Lấy danh sách tất cả các brand
  static List<String> getAllBrands() {
    return allCars.map((car) => car.brand).toSet().toList();
  }
}
