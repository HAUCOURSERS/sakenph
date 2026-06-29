import 'package:sakenph/classes/terminal_class.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  final database = Supabase.instance.client;

  Future<List<Terminal>> get terminalList async {
    List<Terminal> list = [];

    final data = await database.from('terminals').select().eq('type', 'jeep');

    for (var terminal in data) {
      list.add(
        Terminal(
          id: terminal['id'],
          name: terminal['terminal_name'],
          longitude: terminal['longitude'],
          latitude: terminal['latitude'],
          type: terminal['type'],
        ),
      );
    }

    return list;
  }

  Future<List<Terminal>> get todaList async {
    List<Terminal> list = [];

    final data = await database
        .from('terminals')
        .select()
        .eq('type', 'tricycle');

    for (var terminal in data) {
      list.add(
        Terminal(
          id: terminal['id'],
          name: terminal['terminal_name'],
          longitude: terminal['longitude'],
          latitude: terminal['latitude'],
          type: terminal['type'],
        ),
      );
    }

    return list;
  }

  Future<Terminal> getTerminalById(int id) async {
    final data = await database.from('terminals').select().eq('id', id);

    final terminal = data[0];
    return Terminal(
      id: terminal['id'],
      name: terminal['terminal_name'],
      longitude: terminal['longitude'],
      latitude: terminal['latitude'],
      type: terminal['type'],
    );
  }
}
