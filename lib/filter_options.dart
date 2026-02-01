class FilterOption {
  final String id;
  final String label;

  const FilterOption({required this.id, required this.label});
}

const List<FilterOption> occasionFilterOptions = [
  FilterOption(id: 'birthday', label: 'Туған күн'),
  FilterOption(id: 'love', label: 'Махаббат / романтика'),
  FilterOption(id: 'wedding', label: 'Үйлену тойы'),
  FilterOption(id: 'congrats', label: 'Құттықтау'),
  FilterOption(id: 'no_reason', label: 'Себепсіз'),
];

const List<FilterOption> recipientFilterOptions = [
  FilterOption(id: 'girl', label: 'Қызға'),
  FilterOption(id: 'mom', label: 'Анаға'),
  FilterOption(id: 'friend', label: 'Құрбыға'),
  FilterOption(id: 'colleague', label: 'Әріптеске'),
  FilterOption(id: 'universal', label: 'Әмбебап'),
];

String? labelForFilterOption(List<FilterOption> options, String? id) {
  if (id == null) return null;
  for (final option in options) {
    if (option.id == id) return option.label;
  }
  return null;
}
