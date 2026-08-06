import '../models/concept.dart';
import '../models/knowledge_graph.dart';
import '../models/transcript.dart';

/// Builds a [KnowledgeGraph] from concepts extracted across transcripts.
///
/// Two concepts are connected when they co-occur within the same transcript
/// segment; the edge weight reflects how often that happens.
class KnowledgeGraphBuilder {
  const KnowledgeGraphBuilder();

  KnowledgeGraph build(List<Concept> allConcepts, {List<Transcript>? transcripts}) {
    var graph = const KnowledgeGraph();
    for (final concept in allConcepts) {
      graph = graph.addConcept(concept);
    }

    final conceptsByMedia = <String, List<Concept>>{};
    for (final concept in allConcepts) {
      for (final occurrence in concept.occurrences) {
        conceptsByMedia
            .putIfAbsent(occurrence.mediaId, () => [])
            .add(concept);
      }
    }

    // Prefer segment-level co-occurrence when transcripts are supplied.
    if (transcripts != null && transcripts.isNotEmpty) {
      graph = _connectFromTranscripts(graph, allConcepts, transcripts);
    } else {
      graph = _connectFromOccurrences(graph, allConcepts, conceptsByMedia);
    }

    return graph;
  }

  KnowledgeGraph _connectFromTranscripts(
    KnowledgeGraph graph,
    List<Concept> allConcepts,
    List<Transcript> transcripts,
  ) {
    var result = graph;
    final labelToConcept = {for (final c in allConcepts) c.label: c};
    for (final transcript in transcripts) {
      for (final segment in transcript.segments) {
        final present = labelToConcept.keys
            .where(segment.text.toLowerCase().contains)
            .toList();
        if (present.length < 2) continue;
        final ids = present.map((l) => labelToConcept[l]!.id).toList();
        for (var i = 0; i < ids.length; i++) {
          for (var j = i + 1; j < ids.length; j++) {
            result = result.addEdge(ids[i], ids[j]);
          }
        }
      }
    }
    return result;
  }

  KnowledgeGraph _connectFromOccurrences(
    KnowledgeGraph graph,
    List<Concept> allConcepts,
    Map<String, List<Concept>> conceptsByMedia,
  ) {
    var result = graph;
    for (final concepts in conceptsByMedia.values) {
      for (var i = 0; i < concepts.length; i++) {
        for (var j = i + 1; j < concepts.length; j++) {
          result = result.addEdge(concepts[i].id, concepts[j].id);
        }
      }
    }
    return result;
  }
}
