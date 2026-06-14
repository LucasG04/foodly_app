import 'ingredient.dart';

/// The kind of input sent to the streaming `generate-meal` endpoint. The
/// [wireValue] is the `type` field of the request body.
enum MealGenerationSource {
  text('text'),
  instagram('instagram');

  const MealGenerationSource(this.wireValue);

  final String wireValue;
}

/// Terminal error codes the `generate-meal` stream can surface. Unknown codes
/// (e.g. a future server-side code) map to [unknown] so an older client cannot
/// crash on them.
enum MealGenerationErrorCode {
  notFoodRelated('NOT_FOOD_RELATED'),
  instagramFetchFailed('INSTAGRAM_FETCH_FAILED'),
  internal('INTERNAL'),

  /// Client-generated when the stream closes without a terminal event.
  streamInterrupted('STREAM_INTERRUPTED'),
  unknown('UNKNOWN');

  const MealGenerationErrorCode(this.wireValue);

  final String wireValue;

  static MealGenerationErrorCode fromWire(String? value) => values.firstWhere(
        (code) => code.wireValue == value,
        orElse: () => unknown,
      );
}

/// A single event from the streaming `generate-meal` endpoint.
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
      case 'enrichment.group':
        return GroupEvent(
          index: json['index'] as int,
          group: json['group'] as String,
        );
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
        return ErrorEvent(
          code: MealGenerationErrorCode.fromWire(json['code'] as String?),
        );
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

/// The display group label for the ingredient at [index]. Emitted during the
/// enriching phase for grouped ingredients only (M ≤ N); the label is always
/// non-empty and shared by ≥3 ingredients.
class GroupEvent extends MealGenerationEvent {
  final int index;
  final String group;

  const GroupEvent({required this.index, required this.group});
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
  final MealGenerationErrorCode code;

  const ErrorEvent({required this.code});
}

/// An event type the client does not understand. Ignored by the consumer.
class MealGenerationUnknownEvent extends MealGenerationEvent {
  final String rawType;

  const MealGenerationUnknownEvent(this.rawType);
}
