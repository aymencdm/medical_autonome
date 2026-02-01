import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/stream_service.dart';
import 'add_person_screen.dart';

class PersonsScreen extends StatefulWidget {
  const PersonsScreen({super.key});

  @override
  State<PersonsScreen> createState() => _PersonsScreenState();
}

class _PersonsScreenState extends State<PersonsScreen> {
  List<String> _persons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    // Fetch initial list
    context.read<StreamService>().getPersons();
  }

  void _setupListeners() {
    // We need to access the socket directly or expose a stream from StreamService.
    // For now, let's assume we can listen to the socket events via the StreamService if we exposed the socket,
    // OR, better, let's just use the StreamService to trigger updates.
    // 
    // Ideally StreamService should handle the state, but for speed, let's hack a listener here
    // by adding a specialized getter/setter or just re-requesting.
    //
    // Actually, Cleaner Approach: StreamService notifies listeners when 'persons_list' arrives?
    // Let's implement a listener pattern or polling for this simple UI.
    
    // Quick Fix: Access private socket for event listening (requires making it public or adding a method)
    // For now let's just Poll or assume the Service should notify us.
    //
    // Let's modify StreamService to hold the list? Or just define a callback.
    // 
    // Let's look at StreamService again. It has `_socket`.
    // I will add a dirty hack to listen to events here using a helper in StreamService
    // OR create a method `onPersonsList`.
    
    // Best: Update StreamService to handle 'persons_list' event and update a property.
    // I will do that in the next step. For now, let's assume `StreamService` has `persons` list.
  }
  
  @override
  Widget build(BuildContext context) {
    // Consuming local state for now, assuming future integration
    final streamService = context.watch<StreamService>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text('Manage Persons'),
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<StreamService>(
        builder: (context, service, _) {
           return service.persons.isEmpty 
               ? _buildEmptyState() 
               : ListView.builder(
                   itemCount: service.persons.length,
                   itemBuilder: (context, index) {
                     return ListTile(
                       leading: const CircleAvatar(child: Icon(Icons.person)),
                       title: Text(service.persons[index], style: const TextStyle(color: Colors.white)),
                     );
                   },
                 );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPersonScreen()),
          ).then((_) {
             // Refresh list on return
             context.read<StreamService>().getPersons();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           const Icon(Icons.person_off, size: 64, color: Colors.white24),
           const SizedBox(height: 16),
           const Text(
             "No people found.",
             style: TextStyle(color: Colors.white54),
           ),
           TextButton.icon(
             icon: const Icon(Icons.refresh),
             label: const Text("Refresh"),
             onPressed: () => context.read<StreamService>().getPersons(),
           )
         ],
       ),
     );
  }
}
