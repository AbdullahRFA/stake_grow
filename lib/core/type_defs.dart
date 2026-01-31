import 'package:fpdart/fpdart.dart';
import 'failure.dart';

// এখন থেকে আমরা 'FutureEither<int>' লিখলেই বুঝব এটি ফিউচার রিটার্ন করবে,
// যা সফল হলে int দিবে আর ব্যর্থ হলে Failure দিবে।
typedef FutureEither<T> = Future<Either<Failure, T>>;