import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

class RwPage extends StatelessWidget {
  const RwPage({required this.children, this.physics, super.key});
  final List<Widget> children;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      physics: physics,
      padding: const EdgeInsets.all(RwSpace.screen),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: RwSize.contentMax),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class RwSectionTitle extends StatelessWidget {
  const RwSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: RwSpace.xl, bottom: RwSpace.md),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
