library linksco;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

part 'constants.dart';
part 'emailParser.dart';
part 'httpParser.dart';
part 'link.dart';
part 'parser.dart';
part 'telParser.dart';

class Linksco extends StatefulWidget {
  final String text;

  final Color? textColor;

  final Color? linkColor;

  final TextStyle? style;

  final TextAlign? textAlign;

  final TextDirection? textDirection;

  final int? maxLines;

  final double? textScaleFactor;

  final StrutStyle? strutStyle;

  final TextWidthBasis? textWidthBasis;

  final TextHeightBehavior? textHeightBehavior;

  Linksco({
    Key? key,
    required this.text,
    this.textColor = Colors.black,
    this.linkColor = Colors.blue,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textScaleFactor = 1.0,
    this.maxLines,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
  }) : super(key: key);
  @override
  State<Linksco> createState() => _LinkscoState();
}

class _LinkscoState extends State<Linksco> {
  List<Parser> _parsers = <Parser>[];
  List<Link> _links = <Link>[];

  @override
  Widget build(BuildContext context) {
    init();
    return SelectableText.rich(
      TextSpan(
        text: '',
        style: widget.style,
        children: _getTextSpans(),
      ),
      textAlign: widget.textAlign,
      textDirection: widget.textDirection,
      textScaleFactor: widget.textScaleFactor,
      maxLines: widget.maxLines,
      strutStyle: widget.strutStyle,
      textWidthBasis: widget.textWidthBasis,
      textHeightBehavior: widget.textHeightBehavior,
    );
  }

  _getTextSpans() {
    List<TextSpan> _textSpans = <TextSpan>[];
    int i = 0;
    int pos = 0;
    while (i < widget.text.length) {
      _textSpans.add(_text(widget.text.substring(
          i,
          pos < _links.length && i <= _links[pos].regExpMatch.start
              ? _links[pos].regExpMatch.start
              : widget.text.length)));
      if (pos < _links.length && i <= _links[pos].regExpMatch.start) {
        _textSpans.add(_link(
            widget.text.substring(
                _links[pos].regExpMatch.start, _links[pos].regExpMatch.end),
            _links[pos].type));
        i = _links[pos].regExpMatch.end;
        pos++;
      } else {
        i = widget.text.length;
      }
    }
    return _textSpans;
  }

  _text(String text) {
    return TextSpan(text: text, style: TextStyle(color: widget.textColor));
  }

  _link(String text, String type) {
    return TextSpan(
        text: text,
        style: TextStyle(color: widget.linkColor),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            _launch(_getUrl(text, type));
          });
  }

  _launch(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  _getUrl(String text, String type) {
    switch (type) {
      case http:
        return text.substring(0, 4) == 'http' ? text : 'http://$text';
      case email:
        return text.substring(0, 7) == 'mailto:' ? text : 'mailto:$text';
      case tel:
        return text.substring(0, 4) == 'tel:' ? text : 'tel:$text';
      default:
        return text;
    }
  }

  void init() {
    setState(() {
      _addParsers();
      _parseLinks();
      _filterLinks();
    });
  }

  _addParsers() {
    final text = widget.text;
    _parsers.add(EmailParser(text));
    _parsers.add(HttpParser(text));
    _parsers.add(TelParser(text));
  }

  _parseLinks() {
    for (Parser parser in _parsers) {
      _links.addAll(parser.parse().toList());
    }
  }

  _filterLinks() {
    _links.sort(
        (Link a, Link b) => a.regExpMatch.start.compareTo(b.regExpMatch.start));

    List<Link> _filteredLinks = <Link>[];
    if (_links.length > 0) {
      _filteredLinks.add(_links[0]);
    }

    for (int i = 0; i < _links.length - 1; i++) {
      if (_links[i + 1].regExpMatch.start > _links[i].regExpMatch.end) {
        _filteredLinks.add(_links[i + 1]);
      }
    }
    _links = _filteredLinks;
  }
}
