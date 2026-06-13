import 'ingredient.dart';

/// A single event from the streaming `generate-meal-from-text` endpoint.
///
/// The server sends one JSON object per line (NDJSON). [MealGenerationEvent.fromJson]
/// maps each object onto a concrete subtype. Unknown event types map to
/// [MealGenerationUnknownEvent] so a future server-side event cannot crash an
/// older client.
sealed class MealGenerationEvent {
  const MealGenerationEvent();

  factory MealGenerationEvent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'meal.field':
        return MealFieldEvent(
          field: json['field'] as String,
          value: json['value'],
        );
      case 'meal.ingredient':
        return MealIngredientEvent(
          index: json['index'] as int,
          ingredient: Ingredient.fromMap(
            Map<String, dynamic>.from(json['value'] as Map),
          ),
        );
      case 'phase':
        return PhaseEvent(value: json['value'] as String);
      case 'enrichment.productGroup':
        return ProductGroupEvent(
          index: json['index'] as int,
          productGroup: json['productGroup'] as String,
        );
      case 'enrichment.image':
        return ImageEvent(imageUrl: json['imageUrl'] as String?);
      case 'done':
        return const DoneEvent();
      case 'error':
        return ErrorEvent(code: json['code'] as String? ?? 'UNKNOWN');
      default:
        return MealGenerationUnknownEvent(type ?? 'null');
    }
  }
}

/// A top-level meal field. [value] is dynamic because `name`/`instructions`
/// are strings while `servings`/`duration` are numbers; the consumer coerces
/// per field.
class MealFieldEvent extends MealGenerationEvent {
  final String field; // 'name' | 'servings' | 'duration' | 'instructions'
  final dynamic value;

  const MealFieldEvent({required this.field, required this.value});
}

/// A single ingredient at a stable [index]. Enrichment events reference the
/// same index later.
class MealIngredientEvent extends MealGenerationEvent {
  final int index;
  final Ingredient ingredient;

  const MealIngredientEvent({required this.index, required this.ingredient});
}

/// A generation phase change, e.g. `enriching` once the LLM is done.
class PhaseEvent extends MealGenerationEvent {
  final String value;

  const PhaseEvent({required this.value});
}

/// The resolved grocery product group for the ingredient at [index]. Arrives
/// asynchronously and may be in any order.
class ProductGroupEvent extends MealGenerationEvent {
  final int index;
  final String productGroup;

  const ProductGroupEvent({required this.index, required this.productGroup});
}

/// The resolved title image. [imageUrl] may be null when none was found.
class ImageEvent extends MealGenerationEvent {
  final String? imageUrl;

  const ImageEvent({required this.imageUrl});
}

/// Terminal success.
class DoneEvent extends MealGenerationEvent {
  const DoneEvent();
}

/// Terminal failure after the stream started. Partial content should be kept.
class ErrorEvent extends MealGenerationEvent {
  final String code;

  const ErrorEvent({required this.code});
}

/// An event type the client does not understand. Ignored by the consumer.
class MealGenerationUnknownEvent extends MealGenerationEvent {
  final String rawType;

  const MealGenerationUnknownEvent(this.rawType);
}
