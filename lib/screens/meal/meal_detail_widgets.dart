import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants.dart';
import '../../models/image_credit.dart';
import '../../models/ingredient.dart';
import '../../utils/basic_utils.dart';
import '../../utils/convert_util.dart';
import '../../widgets/foodly_network_image.dart';
import '../../widgets/image_credit_chip.dart';
import 'border_icon.dart';
import 'tag_tile.dart';

// Building blocks of a recipe page, shared by MealScreen and the library
// recipe (LibraryMealScreen) so both look the same.

/// Photo header with photo credit, back button and an optional [action].
class MealImageAppBar extends StatelessWidget {
  final String? imageUrl;
  final ImageCredit? imageCredit;
  final Widget? action;

  const MealImageAppBar({
    required this.imageUrl,
    this.imageCredit,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return SliverAppBar(
      expandedHeight: size.width > 700.0 ? 400.0 : 250.0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 4,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        // ignore: avoid_redundant_argument_values
        stretchModes: const <StretchMode>[StretchMode.zoomBackground],
        titlePadding: EdgeInsets.zero,
        background: Stack(
          children: [
            Positioned.fill(
              child: hasImage
                  ? FoodlyNetworkImage(imageUrl!)
                  : Image.asset(
                      'assets/images/food_fallback.png',
                      fit: BoxFit.cover,
                    ),
            ),
            if (hasImage && imageCredit != null)
              Positioned(
                right: kPadding / 4,
                bottom: kPadding / 4,
                left: kPadding / 4,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: ImageCreditChip(imageCredit),
                ),
              ),
            Positioned(
              width: size.width,
              top: kPadding / 2 + MediaQuery.paddingOf(context).top,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const BorderIcon(
                        height: 50,
                        width: 50,
                        child: Icon(
                          EvaIcons.arrowBackOutline,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    action ?? const SizedBox(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      title: const SizedBox(),
      leading: const SizedBox(),
    );
  }
}

/// The page body: [children] stacked at content width, each adding its own
/// side padding (the tag row scrolls edge to edge).
class MealDetailBody extends StatelessWidget {
  final List<Widget> children;

  const MealDetailBody({required this.children, super.key});

  @override
  Widget build(BuildContext context) {
    final width = BasicUtils.contentWidth(context, smallMultiplier: 1);
    return SliverToBoxAdapter(
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        ),
      ),
    );
  }
}

/// Name with a subtitle (the source) on the left; duration and kcal on the
/// right. [kcal] of a recipe for [mealServings] is shown for [servings].
class MealHeadline extends StatelessWidget {
  final String name;

  /// Shown as "from tasty.co" (the host of a URL, else the text itself).
  final String? source;
  final int? duration;
  final int? kcal;
  final int mealServings;
  final int servings;

  const MealHeadline({
    required this.name,
    required this.source,
    required this.duration,
    required this.kcal,
    required this.mealServings,
    required this.servings,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shownKcal = _scaledKcal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  name,
                  // Shrink a bit so a long word ("Älplermagronen") isn't split;
                  // below minFontSize it wraps (e.g. at the hyphens of
                  // "Hähnchen-Speck-Brokkoli-Alfredo-Spaghetti").
                  wrapWords: false,
                  minFontSize: 20,
                  style: const TextStyle(
                    fontSize: 26.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5.0),
                Text(
                  source != null && source!.isNotEmpty
                      ? context.tr('meal_details_source_known',
                          args: [_sourceLabel(source!)])
                      : context.tr('meal_details_source_unknown'),
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge!.color!
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _chip(
                context.tr('meal_details_duration_trailing',
                    args: [(duration ?? '?').toString()]),
                fontSize: 20.0,
              ),
              if (shownKcal != null && shownKcal > 0) ...[
                const SizedBox(height: 8),
                _chip(
                  context.tr(
                    servings != mealServings
                        ? 'meal_details_kcal_scaled'
                        : 'meal_details_kcal',
                    args: [shownKcal.toString()],
                  ),
                  fontSize: 16.0,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {required double fontSize}) {
    return BorderIcon(
      padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 15),
      withBorder: true,
      child: Text(
        text,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
      ),
    );
  }

  static String _sourceLabel(String source) => BasicUtils.isValidUri(source)
      ? Uri.parse(source).host.replaceAll('www.', '')
      : source;

  int? get _scaledKcal {
    if (kcal == null || mealServings <= 0) {
      return kcal;
    }
    return (kcal! / mealServings * servings).round();
  }
}

/// Tags, scrolling edge to edge.
class MealTagRow extends StatelessWidget {
  final List<String> tags;

  const MealTagRow(this.tags, {super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...tags.map(TagTile.new),
          const SizedBox(width: kPadding),
        ],
      ),
    );
  }
}

/// A titled section, e.g. ingredients with the servings input as [trailing].
class MealSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const MealSection({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const sidePadding = EdgeInsets.symmetric(horizontal: kPadding);
    final titleText = Text(
      title,
      style: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: sidePadding,
          child: trailing == null
              ? titleText
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Flexible(child: titleText), trailing!],
                ),
        ),
        const SizedBox(height: kPadding / 2),
        Container(width: double.infinity, padding: sidePadding, child: child),
      ],
    );
  }
}

/// Ingredients sorted by group ([groupOrder]) and sort key, under group
/// headers when there are named groups. Amounts are scaled from
/// [mealServings] to [servings].
class MealIngredientList extends StatelessWidget {
  final List<Ingredient> ingredients;
  final List<String>? groupOrder;
  final int servings;
  final int mealServings;

  const MealIngredientList({
    required this.ingredients,
    required this.servings,
    required this.mealServings,
    this.groupOrder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final groups = Ingredient.orderedGroupsSorted(ingredients, groupOrder);
    final grouped = ingredients.any((i) => i.group != null);
    final widgets = <Widget>[];
    for (final group in groups) {
      final items = ingredients.where((i) => i.group == group).toList()
        ..sort((a, b) => (a.sortKey ?? 9999).compareTo(b.sortKey ?? 9999));
      if (items.isEmpty) {
        continue;
      }
      if (group != null) {
        widgets.addAll([
          if (widgets.isNotEmpty) const SizedBox(height: kPadding / 2),
          Text(
            group,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: kPadding / 2),
        ]);
      }
      for (var i = 0; i < items.length; i++) {
        if (i > 0) {
          widgets.add(grouped
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: kPadding / 2),
                  child: Divider(),
                )
              : const Divider());
        }
        widgets.add(_buildTile(items[i]));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTile(Ingredient ingredient) {
    final amount = ConvertUtil.calculateServingsAmount(
      requestedServings: servings,
      mealServings: mealServings,
      amount: ingredient.amount,
    );
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SizedBox(
            width: constraints.maxWidth * 0.3 - kPadding / 2,
            child: Text(
              ConvertUtil.amountToString(amount, ingredient.unit),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
          SizedBox(
            width: constraints.maxWidth * 0.5 - kPadding / 2,
            child: Text(
              ingredient.name.toString(),
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
        ],
      );
    });
  }
}

/// Instructions as markdown; links open in the browser.
class MealInstructions extends StatelessWidget {
  final String text;

  const MealInstructions(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      onTapLink: (_, href, __) {
        final uri = href == null ? null : Uri.tryParse(href);
        if (uri != null) {
          launchUrl(uri);
        }
      },
      styleSheet: MarkdownStyleSheet.fromTheme(
        ThemeData(
          textTheme: const TextTheme(
            bodyLarge: TextStyle(fontSize: 16),
            bodyMedium: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
