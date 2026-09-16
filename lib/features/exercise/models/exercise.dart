/// Placeholder content only. `videoUrl` is nullable and unused today —
/// deliberately present so a real video source can be configured later
/// without restructuring this model or the screens that use it.
class Exercise {
  const Exercise({required this.title, this.videoUrl});

  final String title;
  final String? videoUrl;
}

const sampleExercises = [
  Exercise(title: 'Sample exercise topic 1'),
  Exercise(title: 'Sample exercise topic 2'),
  Exercise(title: 'Sample exercise topic 3'),
];
