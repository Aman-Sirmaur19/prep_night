import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../api/apis.dart';
import '../main.dart';
import '../helper/dialogs.dart';

import '../models/category.dart';
import './pdf_viewer_screen.dart';

class PdfScreen extends StatefulWidget {
  final Category category;

  const PdfScreen({super.key, required this.category});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  List<Map<String, dynamic>> pdfData = [];
  List<Map<String, dynamic>> pdfDataList = [];

  bool _isLoading = true;

  // for storing search status
  bool _isSearching = false;

  //for storing searched items
  final List<Map<String, dynamic>> _searchList = [];

  // for accessing files
  void getAllPdfs() async {
    final results =
        await APIs.storage.ref('PDFs/${widget.category.title}').listAll();
    pdfData = await Future.wait(
      results.items
          .where((item) => item.name.endsWith('.pdf'))
          .map((item) async {
        final downloadUrl = await item.getDownloadURL();
        final metadata = await item.getMetadata();
        final uploaderId = metadata.customMetadata!['uploader']!;
        final uploaderName = await APIs.getUserName(uploaderId);
        final pdfId = metadata.customMetadata!['pdfId']!;
        return {
          'name': item.name,
          'url': item.fullPath,
          'metadata': metadata,
          'uploader': uploaderName,
          'uploaderId': uploaderId,
          'pdfId': pdfId,
          'downloadUrl': downloadUrl,
        };
      }).toList(),
    );
    setState(() {
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> fetchPdfData() async {
    try {
      // Get a reference to the 'pdfs' collection
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('pdfs').get();

      // Convert the QuerySnapshot into a List<Map<String, dynamic>>
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> pdfInfo = doc.data();
        pdfInfo['pdfId'] = doc.id; // Add the document ID to the data
        pdfDataList.add(pdfInfo);
      }

      return pdfDataList;
    } catch (e) {
      print("Error fetching PDF data: $e");
      throw e;
    }
  }

  @override
  void initState() {
    super.initState();
    getAllPdfs();
    fetchPdfData();
  }

  Future<void> _refresh() async {
    getAllPdfs();
    fetchPdfData();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        onPopInvoked: (bool _) {
          if (_isSearching) {
            setState(() {
              _isSearching = !_isSearching;
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter PDF name...',
                    ),
                    autofocus: true,
                    style: const TextStyle(fontSize: 17, letterSpacing: 1),

                    // when search text changes, update search list
                    onChanged: (val) {
                      // search logic
                      _searchList.clear();
                      for (var i in pdfData) {
                        if (i['name']
                            .toLowerCase()
                            .contains(val.toLowerCase())) {
                          _searchList.add(i);
                        }
                        setState(() {
                          _searchList;
                        });
                      }
                    },
                  )
                : Text(
                    widget.category.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(_isSearching
                    ? CupertinoIcons.clear_circled_solid
                    : CupertinoIcons.search),
                tooltip: 'Search',
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
              ),
            ],
            backgroundColor: widget.category.color.withOpacity(.7),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : pdfData.isEmpty
                  ? SingleChildScrollView(child: _pdfDataIsEmpty())
                  : _pdfDataIsNotEmpty(),
        ),
      ),
    );
  }

  Widget _pdfDataIsEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: mq.height * .07),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: mq.height * .04),
              child: const Text(
                'Nothing uploaded yet!',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Image.asset(widget.category.image, width: mq.width * .5),
          ],
        ),
      ),
    );
  }

  Widget _pdfDataIsNotEmpty() {
    return ListView.builder(
      itemCount: _isSearching ? _searchList.length : pdfData.length,
      itemBuilder: (context, index) {
        int i = pdfDataList.indexWhere((element) =>
            element['pdfId'].toString() == pdfData[index]['pdfId']);
        bool userLiked =
            pdfDataList[i]['likes']?.contains(APIs.user.uid) ?? false;
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => PdfViewerScreen(
                        pdfName: _isSearching
                            ? _searchList[index]['name']
                            : pdfData[index]['name'],
                        pdfUrl: _isSearching
                            ? _searchList[index]['url']
                            : pdfData[index]['url'],
                      )));
            },
            child: ListTile(
              leading:
                  Image.asset(widget.category.image, width: mq.width * .15),
              title: Text(
                _isSearching
                    ? _searchList[index]['name'].split('.').first
                    : pdfData[index]['name'].split('.').first,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                children: [
                  Text(
                    _isSearching
                        ? _searchList[index]['uploader']
                        : pdfData[index]['uploader'],
                    style: const TextStyle(
                      color: Colors.grey,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: mq.width * .03),
                    child: IconButton(
                      color: Colors.blue,
                      icon: userLiked
                          ? const Icon(Icons.thumb_up_alt_rounded)
                          : const Icon(Icons.thumb_up_alt_outlined),
                      onPressed: () async {
                        final pdfRef = APIs.firestore
                            .collection('pdfs')
                            .doc(pdfData[index]['pdfId']);
                        final docSnapshot = await pdfRef.get();
                        final currentLikes =
                            List<String>.from(docSnapshot.data()?['likes']);
                        if (!currentLikes.contains(APIs.user.uid)) {
                          currentLikes.add(APIs.user.uid);
                          await pdfRef.update({'likes': currentLikes});
                          setState(() {
                            pdfDataList[i]['likes']?.add(APIs.user.uid);
                            userLiked = true;
                          });
                        } else {
                          currentLikes.remove(APIs.user.uid);
                          await pdfRef.update({'likes': currentLikes});
                          setState(() {
                            pdfDataList[i]['likes']?.remove(APIs.user.uid);
                            userLiked = false;
                          });
                        }
                      },
                    ),
                  ),
                  Text(pdfDataList[i]['likes'].length.toString(),
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold)),
                  if (APIs.user.uid == pdfData[index]['uploaderId'])
                    Padding(
                      padding: EdgeInsets.only(left: mq.width * .03),
                      child: IconButton(
                        color: Colors.red,
                        icon: const Icon(Icons.delete_rounded),
                        onPressed: () => showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text(
                                  'Do you want to delete?',
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                                content: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    TextButton(
                                      child: Text('Yes',
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary)),
                                      onPressed: () async {
                                        await APIs.firestore
                                            .collection('pdfs')
                                            .doc(pdfData[index]['pdfId'])
                                            .delete();
                                        await APIs.storage
                                            .ref()
                                            .child(
                                                'PDFs/${widget.category.title}/${pdfData[index]['name']}')
                                            .delete()
                                            .then((value) =>
                                                Dialogs.showSnackBar(context,
                                                    'Deleted successfully!'));
                                        await APIs.updateUploads(-1);
                                        Navigator.pop(context);
                                        _refresh();
                                      },
                                    ),
                                    TextButton(
                                        child: Text('No',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary)),
                                        onPressed: () =>
                                            Navigator.pop(context)),
                                  ],
                                ),
                              );
                            }),
                      ),
                    )
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => downloadPdf(pdfData[index]['downloadUrl']),
              ),
            ),
          ),
        );
      },
    );
  }

  Future downloadPdf(Reference ref) async {}
}
