import 'evaluation_config.dart';

class SubjectEvaluationConfig {
  final String subject;
  final EvaluationConfig config;

  const SubjectEvaluationConfig({
    required this.subject,
    required this.config,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'config': config.toMap(),
    };
  }

  factory SubjectEvaluationConfig.fromMap(
    Map<String, dynamic> map,
  ) {
    return SubjectEvaluationConfig(
      subject: map['subject'].toString(),
      config: EvaluationConfig.fromMap(
        Map<String, dynamic>.from(map['config']),
      ),
    );
  }
}