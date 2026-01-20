abstract class Failure {
  final String message;
  Failure(this.message);
}

class DatabaseFailure extends Failure {
  DatabaseFailure(super.message);
}

class FileFailure extends Failure {
  FileFailure(super.message);
}

class ServerFailure extends Failure {
  ServerFailure(super.message);
}
