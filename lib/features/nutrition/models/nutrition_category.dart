/// Placeholder content only — deliberately generic (not real medical
/// guidance) until reviewed nutrition content exists. Screens consume this
/// list regardless of where it comes from, so swapping in a real
/// repository later doesn't require restructuring the UI.
class NutritionCategory {
  const NutritionCategory({required this.title});

  final String title;
}

const sampleNutritionCategories = [
  NutritionCategory(title: 'Sample nutrition topic 1'),
  NutritionCategory(title: 'Sample nutrition topic 2'),
  NutritionCategory(title: 'Sample nutrition topic 3'),
  NutritionCategory(title: 'Sample nutrition topic 4'),
];
