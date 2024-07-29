import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class Crontab {
  static final Crontab _instance = Crontab._internal();

  final Map<String, Timer> _timers = {};

  factory Crontab() {
    return _instance;
  }

  Crontab._internal();

  Future<void> scheduleJob(String jobId, Duration interval, Future<void> Function() job) async {
    //print('Scheduling job: $jobId'); // Print each time the method is called

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Run the job immediately
    //print('Running job immediately: $jobId');
    await job();
    await prefs.setInt('lastRun_$jobId', DateTime.now().millisecondsSinceEpoch);

    // Schedule the job to run periodically based on the interval
    _timers[jobId]?.cancel();
    _timers[jobId] = Timer.periodic(interval, (timer) async {
      //print('Periodic run of job: $jobId');
      await job();
      await prefs.setInt('lastRun_$jobId', DateTime.now().millisecondsSinceEpoch);
    });
  }

  void cancelJob(String jobId) {
    //print('Canceling job: $jobId'); // Print when a job is canceled
    _timers[jobId]?.cancel();
    _timers.remove(jobId);
  }

  void cancelAllJobs() {
    //print('Canceling all jobs'); // Print when all jobs are canceled
    _timers.forEach((_, timer) => timer.cancel());
    _timers.clear();
  }
}

