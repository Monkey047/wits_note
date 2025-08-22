import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class MainPage extends StatefulWidget {
  const MainPage ({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}
class _NoteData {
  String text;
  Offset position;

  _NoteData({required this.text, required this.position});
}

class _MainPageState extends State<MainPage> {
  List<_NoteData> notes = [];

  //To add new notes
  void _addNote() {
    String newNote = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Note'),
        content: TextField(
          autofocus: true,
          maxLines: 3,
          onChanged: (value) => newNote = value,
          decoration: const InputDecoration(hintText: 'Type your note here...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newNote.trim().isNotEmpty) {
                setState(() {
                  notes.add(_NoteData(text: newNote.trim(), position: const Offset(100, 100)));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNotes() async {
    final notesCollection = FirebaseFirestore.instance.collection('notes');

    // Clear existing data first (optional)
    final snapshot = await notesCollection.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Save each note
    for (var note in notes) {
      await notesCollection.add({
        'text': note.text,
        'x': note.position.dx,
        'y': note.position.dy,
      });
    }
  }

  //Edit notes
  void _editNote(int index) {
    String updatedNote = notes[index].text;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          autofocus: true,
          controller: TextEditingController(text: updatedNote),
          onChanged: (value) => updatedNote = value,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (updatedNote.trim().isNotEmpty) {
                setState(() {
                  notes[index].text = updatedNote.trim();
                });
                _saveNotes(); // Save after editing
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  //Delete notes
  void _deleteNote(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Note?"),
        content: const Text("Are you sure you want to delete this note?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                notes.removeAt(index);
              });
              Navigator.pop(context);
              _saveNotes(); // Save after delete
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final snapshot = await FirebaseFirestore.instance.collection('notes').get();
    setState(() {
      notes = snapshot.docs.map((doc) {
        final data = doc.data();
        return _NoteData(
          text: data['text'],
          position: Offset((data['x'] as num).toDouble(), (data['y'] as num).toDouble()),
        );
      }).toList();
    });
  }


  //Notes
  Widget _noteCard(String text, int index) {
    return GestureDetector(
      onTap: () => _editNote(index),
      onLongPress: () => _deleteNote(index),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.yellow[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      ),
    );
  }



  @override //User Interface
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 80,
            color: Colors.grey[300],
            child: Column(
              children: [
                const SizedBox(height: 20),
                IconButton(
                  icon: const Icon(Icons.person),
                  onPressed: () {},
                ),
                const Divider(),
                _sideButton(Icons.note, "Note", _addNote),
                _sideButton(Icons.image, "Media", () {}),
                _sideButton(Icons.circle_outlined, "Shapes", () {}),
                _sideButton(Icons.checklist, "To-do", () {}),
                _sideButton(Icons.label, "Tag", () {}),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  color: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  height: 56,
                  child: Row(
                    children: [
                      const Text('Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const Spacer(),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.undo)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.redo)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.delete)),
                    ],
                  ),
                ),

                // Canvas area
                Expanded(
                  child: Container(
                    color: Colors.black87,
                    child: notes.isEmpty
                        ? const Center(
                      child: Text("No notes yet", style: TextStyle(color: Colors.white70)),
                    )
                        : Expanded(
                      child: Container(
                        color: Colors.black87,
                        child: Stack(
                            children: List.generate(notes.length, (index) {
                              final note = notes[index];
                              return Positioned(
                                left: note.position.dx,
                                top: note.position.dy,
                                child: Draggable(
                                  feedback: _noteCard(note.text, index),
                                  childWhenDragging: const SizedBox.shrink(),
                                  onDragEnd: (details) {
                                    setState(() {
                                      notes[index].position = details.offset - const Offset(80, 56); // adjust for sidebar/topbar
                                    });
                                    _saveNotes(); // Save after dragging
                                  },
                                  child: _noteCard(note.text, index),
                                ),
                              );
                            }),
                        ),
                      ),
                    ),

                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideButton(IconData icon, String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          IconButton(icon: Icon(icon), onPressed: onPressed),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
