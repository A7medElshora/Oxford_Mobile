class Lesson {
  final int id; final String title, duration; final bool isFreePreview, isCompleted;
  Lesson(this.id, this.title, this.duration, this.isFreePreview, this.isCompleted);
  factory Lesson.fromJson(Map j) => Lesson(j['id'] ?? 0, '${j['title'] ?? ''}', '${j['duration'] ?? ''}',
      j['isFreePreview'] == true, j['isCompleted'] == true);
}

class Course {
  final int id, totalLessons; final String title, description, category, imageUrl, instructor, instructorAvatar;
  final num price, durationHours; final bool isEnrolled; final List<Lesson> lessons;
  Course({required this.id, this.title = '', this.description = '', this.category = '', this.imageUrl = '',
      this.instructor = '', this.instructorAvatar = '', this.price = 0, this.durationHours = 0,
      this.totalLessons = 0, this.isEnrolled = false, this.lessons = const []});
  factory Course.fromJson(Map j) => Course(
      id: j['id'] ?? 0, title: '${j['title'] ?? ''}', description: '${j['description'] ?? ''}',
      category: '${j['category'] ?? ''}', imageUrl: '${j['imageUrl'] ?? ''}',
      instructor: '${(j['instructor'] as Map?)?['name'] ?? ''}',
      instructorAvatar: '${(j['instructor'] as Map?)?['avatarUrl'] ?? ''}',
      price: j['price'] ?? 0, durationHours: j['durationHours'] ?? 0, totalLessons: j['totalLessons'] ?? (j['lessons'] as List?)?.length ?? 0,
      isEnrolled: j['isEnrolled'] == true,
      lessons: ((j['lessons'] as List?) ?? []).map((e) => Lesson.fromJson(e)).toList());
  /// placeholder structure used only by Skeletonizer while loading
  static Course fake(int i) => Course(id: -i, title: 'عنوان الكورس التجريبي هنا', description: 'وصف الكورس ' * 6,
      category: 'الفئة', instructor: 'اسم المحاضر', price: 100, durationHours: 10, totalLessons: 12,
      lessons: List.generate(5, (k) => Lesson(-k, 'عنوان الدرس رقم $k', '10:00', false, false)));
}
