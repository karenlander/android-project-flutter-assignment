import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:english_words/english_words.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

import 'auth_repository.dart';
import 'login.dart';

class RandomWords extends StatefulWidget {
  const RandomWords({Key? key}) : super(key: key);

  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  List<WordPair> _suggestions = <WordPair>[];
  Set<WordPair> _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18);
  final beforeNonLeadingCapitalLetter = RegExp(r"(?=(?!^)[A-Z])");
  bool fromDismissable = false;
  final snappingSheetController = SnappingSheetController();

  List<String> splitPascalCase(String input) =>
      input.split(beforeNonLeadingCapitalLetter);

  double sigmaX = 0 ;
  double sigmaY = 0 ;
  Widget buildSuggestions(AuthRepository authentication) {
    if (authentication.isAuthenticated) {
      String? email = authentication.user!.email;
      return Scaffold(
        body: SnappingSheet(
          controller: snappingSheetController,
          initialSnappingPosition: const SnappingPosition.pixels(positionPixels: 140),
          snappingPositions: const [
            SnappingPosition.pixels(positionPixels: 140),
            SnappingPosition.pixels(positionPixels: 30),
          ],
          onSheetMoved: (position) {
            if(position.pixels > 400 ){
              sigmaY = 14;
              sigmaX = 14;
            }else if(position.pixels > 250) {
              sigmaY = 12;
              sigmaX = 12;
            }else if(position.pixels > 30){
              sigmaY = 8;
              sigmaX = 8;
            }else{
              sigmaY = 0;
              sigmaX = 0;
            }
            setState(() {});
          },
          child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(authentication.user?.uid)
                  .collection('SavedSuggestions')
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasData) {
                  snapshot.data!.docs.forEach((document) {
                    List<String> list = splitPascalCase(document['name']);
                    String first = list[0].toLowerCase();
                    String second = list[1].toLowerCase();
                    if (!_saved.contains(WordPair(first, second))) {
                      if (!fromDismissable) {
                        _saved.add(WordPair(first, second));
                      } else {
                        fromDismissable = false;
                      }
                    }
                  });
                }
                return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (BuildContext _context, int i) {
                      if (i.isOdd) {
                        return Divider();
                      }

                      final int index = i ~/ 2;

                      if (index >= _suggestions.length) {
                        _suggestions.addAll(generateWordPairs().take(10));
                      }
                      return _buildRow(_suggestions[index], authentication);
                    });
              }),
          grabbingHeight: 60,
          grabbing: GrabbingWidget(email, snappingSheetController, sigmaX, sigmaY),
          sheetBelow: SnappingSheetContent(
            draggable: true,
            child: SheetContent(email, authentication.user?.uid),
          ),
        ),
      );
    } else {
      return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemBuilder: (BuildContext _context, int i) {
            if (i.isOdd) {
              return Divider();
            }

            final int index = i ~/ 2;

            if (index >= _suggestions.length) {
              _suggestions.addAll(generateWordPairs().take(10));
            }
            return _buildRow(_suggestions[index], authentication);
          });
    }
  }

  Widget _buildRow(WordPair pair, AuthRepository authentication) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved ? Icons.star : Icons.star_border,
        color: alreadySaved ? Colors.deepPurple : null,
        semanticLabel: alreadySaved ? 'Remove from saved' : 'Save',
      ),
      onTap: () {
        setState(() {
          if (alreadySaved) {
            _saved.remove(pair);
            updateDatabase(true, authentication, pair);
            fromDismissable = true;
          } else {
            _saved.add(pair);
            updateDatabase(false, authentication, pair);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRepository>(
      builder: (context, authentication, child) {
        return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Startup Name Generator',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.white),
                  onPressed: () => _pushSaved(authentication),
                  tooltip: 'Saved Suggestions',
                ),
                IconButton(
                  icon: authentication.isAuthenticated
                      ? Icon(Icons.exit_to_app, color: Colors.white)
                      : Icon(Icons.login, color: Colors.white),
                  tooltip: 'Login',
                  onPressed: () {
                    if (!authentication.isAuthenticated) {
                      login(context, _saved);
                    } else {
                      _saved = <WordPair>{};
                      logout(authentication);
                    }
                  },
                ),
              ],
            ),
            body: buildSuggestions(authentication));
      },
    );
  }

  refresh() {
    setState(() {
      fromDismissable = true;
    });
  }

  void _pushSaved(AuthRepository authentication) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
                iconTheme: IconThemeData(
                  color: Colors.white,
                ),
                title: const Text('Saved Suggestions',
                    style: TextStyle(color: Colors.white))),
            body: ListViewWithDismissable(_saved, authentication, refresh),
          );
        },
      ),
    );
  }

  Future<void> logout(AuthRepository authentication) async {
    await authentication.signOut();
    setState(() {});
    final snackBar = SnackBar(content: Text('Successfully logged out'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void login(BuildContext context, Set<WordPair> saved) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return Scaffold(
              appBar: AppBar(
                iconTheme: IconThemeData(
                  color: Colors.white,
                ),
                centerTitle: true,
                title: const Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: LoginForm(saved));
        },
      ),
    );
  }
}

void updateDatabase(
    bool toDelete, AuthRepository authentication, WordPair pair) {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  if (authentication.isAuthenticated) {
    if (toDelete) {
      _firestore
          .collection('users')
          .doc(authentication.user?.uid)
          .collection('SavedSuggestions')
          .doc(pair.asPascalCase)
          .delete();
    } else {
      _firestore
          .collection('users')
          .doc(authentication.user?.uid)
          .collection('SavedSuggestions')
          .doc(pair.asPascalCase)
          .set({'name': pair.asPascalCase});
    }
  }
}

class ListViewWithDismissable extends StatefulWidget {
  Set<WordPair> _saved;
  AuthRepository authentication;
  final Function() notifyParent;

  ListViewWithDismissable(this._saved, this.authentication, this.notifyParent);

  @override
  _ListViewWithDismissableState createState() =>
      _ListViewWithDismissableState();
}

class _ListViewWithDismissableState extends State<ListViewWithDismissable> {
  final _biggerFont = const TextStyle(fontSize: 18);

  @override
  Widget build(BuildContext context) {
    final tiles = widget._saved.map(
      (pair) {
        return ListTile(
          title: Text(
            pair.asPascalCase,
            style: _biggerFont,
          ),
          key: ValueKey<String>(pair.asPascalCase),
        );
      },
    );
    final divided = tiles.isNotEmpty
        ? ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList()
        : <Widget>[];

    return ListView.builder(
      itemCount: divided.length,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemBuilder: (BuildContext context, int index) {
        return Dismissible(
          child: divided[index],
          background: Container(
            color: Colors.deepPurple,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  WidgetSpan(
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  TextSpan(
                      text: 'Delete Suggestion',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          ),
          confirmDismiss: (direction) async {
            return await _dismiss(
                widget._saved.elementAt(index).asPascalCase, index);
          },
          key: ValueKey<Widget>(divided[index]),
        );
      },
    );
  }

  _dismiss(String key, int index) async {
    Widget yesButton = TextButton(
      child: Text("Yes"),
      style: TextButton.styleFrom(
        primary: Colors.white,
        backgroundColor: Colors.deepPurple,
      ),
      onPressed: () {
        Navigator.of(context).pop(true); //dialog returns true
        updateDatabase(
            true, widget.authentication, widget._saved.elementAt(index));
        setState(() {
          widget._saved.remove(widget._saved.elementAt(index));
        });
        widget.notifyParent();
      },
    );

    Widget noButton = TextButton(
      child: Text("No"),
      style: TextButton.styleFrom(
        primary: Colors.white,
        backgroundColor: Colors.deepPurple,
      ),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Delete Suggestion"),
      content: Text(
          "Are you sure you want to delete ${key} from your saved suggestions?"),
      actions: [yesButton, noButton],
    );

    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
