import 'concept.dart';

/// A directed, weighted link between two [Concept]s.
class KnowledgeEdge {
  final String from;
  final String to;

  /// Co-occurrence count.
  final int weight;

  const KnowledgeEdge({required this.from, required this.to, this.weight = 1});

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'weight': weight,
      };

  factory KnowledgeEdge.fromJson(Map<String, dynamic> json) {
    return KnowledgeEdge(
      from: json['from'] as String,
      to: json['to'] as String,
      weight: json['weight'] as int? ?? 1,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KnowledgeEdge &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// A graph connecting concepts that co-occur across the library.
class KnowledgeGraph {
  final List<Concept> nodes;
  final List<KnowledgeEdge> edges;

  const KnowledgeGraph({this.nodes = const [], this.edges = const []});

  /// Adds [concept] as a node (deduplicated by id).
  KnowledgeGraph addConcept(Concept concept) {
    if (nodes.any((n) => n.id == concept.id)) return this;
    return KnowledgeGraph(nodes: [...nodes, concept], edges: edges);
  }

  /// Adds or strengthens the edge between two node ids.
  KnowledgeGraph addEdge(String from, String to) {
    if (from == to) return this;
    final next = <KnowledgeEdge>[];
    var found = false;
    for (final edge in edges) {
      if (edge.from == from && edge.to == to) {
        next.add(KnowledgeEdge(from: from, to: to, weight: edge.weight + 1));
        found = true;
      } else {
        next.add(edge);
      }
    }
    if (!found) {
      next.add(KnowledgeEdge(from: from, to: to));
    }
    return KnowledgeGraph(nodes: nodes, edges: next);
  }

  /// Neighbours of [conceptId], by edge weight descending.
  List<(String, int)> neighboursOf(String conceptId) {
    final result = <String, int>{};
    for (final edge in edges) {
      if (edge.from == conceptId) {
        result[edge.to] = (result[edge.to] ?? 0) + edge.weight;
      } else if (edge.to == conceptId) {
        result[edge.from] = (result[edge.from] ?? 0) + edge.weight;
      }
    }
    final entries = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => (e.key, e.value)).toList();
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };

  factory KnowledgeGraph.fromJson(Map<String, dynamic> json) {
    return KnowledgeGraph(
      nodes: (json['nodes'] as List<dynamic>? ?? const [])
          .map((n) => Concept.fromJson((n as Map).cast<String, dynamic>()))
          .toList(),
      edges: (json['edges'] as List<dynamic>? ?? const [])
          .map((e) => KnowledgeEdge.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  @override
  String toString() => 'KnowledgeGraph(${nodes.length} nodes, ${edges.length} edges)';
}
