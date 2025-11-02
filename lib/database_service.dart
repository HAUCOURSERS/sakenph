import 'package:sakenph/terminal_class.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final database = Supabase.instance.client;

  // List<Terminal> get _terminalLists {
  //   List<Terminal> list;

    
  //   return list;
  // }


  Future<List<Terminal>> get terminalList async {
    List<Terminal> list = [];
    
    final data = await database
      .from('terminals')
      .select();


    for (var terminal in data) {
      list.add(
        Terminal(
          id: terminal['id'],
          name: terminal['terminal_name'],
          longitude: terminal['longitude'],
          latitude: terminal['latitude'],
          type: terminal['type']
        )
      );
    }

    return list;
  }
}