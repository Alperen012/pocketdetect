import 'package:flutter/foundation.dart';

@immutable
class CategoryGroup {
  const CategoryGroup({
    required this.id,
    required this.label,
    required this.items,
  });

  final String id;
  final String label;
  final List<String> items;
}

const List<CategoryGroup> cocoGroups = <CategoryGroup>[
  CategoryGroup(
    id: 'vehicles',
    label: 'Araçlar',
    items: <String>['car', 'truck', 'bus', 'motorbike', 'bicycle', 'train'],
  ),
  CategoryGroup(
    id: 'transport_infra',
    label: 'Ulaşım & Altyapı',
    items: <String>[
      'aeroplane',
      'boat',
      'traffic light',
      'fire hydrant',
      'stop sign',
      'parking meter',
      'bench',
    ],
  ),
  CategoryGroup(
    id: 'animals',
    label: 'Hayvanlar',
    items: <String>[
      'bird',
      'cat',
      'dog',
      'horse',
      'sheep',
      'cow',
      'elephant',
      'bear',
      'zebra',
      'giraffe',
    ],
  ),
  CategoryGroup(
    id: 'electronics',
    label: 'Elektronik',
    items: <String>[
      'tvmonitor',
      'laptop',
      'mouse',
      'remote',
      'keyboard',
      'cell phone',
    ],
  ),
  CategoryGroup(
    id: 'furniture',
    label: 'Mobilya',
    items: <String>['chair', 'sofa', 'bed', 'dining table'],
  ),
  CategoryGroup(
    id: 'clothing',
    label: 'Giyim & Aksesuar',
    items: <String>['person', 'backpack', 'handbag', 'tie', 'suitcase', 'umbrella'],
  ),
  CategoryGroup(
    id: 'sports',
    label: 'Spor & Outdoor',
    items: <String>[
      'frisbee',
      'skis',
      'snowboard',
      'sports ball',
      'kite',
      'baseball bat',
      'baseball glove',
      'skateboard',
      'surfboard',
      'tennis racket',
    ],
  ),
  CategoryGroup(
    id: 'kitchen',
    label: 'Mutfak & Sofra',
    items: <String>['bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl'],
  ),
  CategoryGroup(
    id: 'food',
    label: 'Yiyecek',
    items: <String>[
      'banana',
      'apple',
      'sandwich',
      'orange',
      'broccoli',
      'carrot',
      'hot dog',
      'pizza',
      'donut',
      'cake',
    ],
  ),
  CategoryGroup(
    id: 'home_appliances',
    label: 'Ev Aletleri',
    items: <String>[
      'toilet',
      'microwave',
      'oven',
      'toaster',
      'sink',
      'refrigerator',
    ],
  ),
  CategoryGroup(
    id: 'household',
    label: 'Ev Eşyaları',
    items: <String>[
      'book',
      'clock',
      'vase',
      'scissors',
      'teddy bear',
      'hair drier',
      'toothbrush',
    ],
  ),
  CategoryGroup(
    id: 'plants',
    label: 'Bitkiler',
    items: <String>['potted plant'],
  ),
];
