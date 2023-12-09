import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class ChatGPTSheetComponent extends StatefulWidget {
  final String initialPrompt;
  final ScrollController scrollController;
  final List<String> recentList;
  final bool shortReply;
  final bool testWithoutKey;
  final Widget? loaderWidget;
  final InputDecoration? promptFieldInputDecoration;
  final String promptPrefix;

  final ChatGPTModuleStrings gptModuleStrings;

  ChatGPTSheetComponent({
    super.key,
    this.initialPrompt = '',
    required this.recentList,
    this.shortReply = false,
    this.testWithoutKey = false,
    this.promptFieldInputDecoration,
    required this.scrollController,
    this.loaderWidget,
    this.promptPrefix = 'Tune this',
    required this.gptModuleStrings,
  });

  @override
  State<ChatGPTSheetComponent> createState() => _ChatGPTSheetComponentState();
}

class _ChatGPTSheetComponentState extends State<ChatGPTSheetComponent> {
  TextEditingController promptCont = TextEditingController();
  TextEditingController answerCont = TextEditingController();

  bool displayGeneratedText = false;
  bool isTextAnimationCompleted = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    if (widget.initialPrompt.isNotEmpty) {
      promptCont.text = widget.initialPrompt;
    }
  }

  void handleGenerateClick(BuildContext context) async {
    if (isLoading ||
        (answerCont.text.isNotEmpty && !isTextAnimationCompleted)) {
      toast(widget.gptModuleStrings.pleaseWaitGeneratingContent);
      return;
    }
    if (promptCont.text.isEmpty) {
      toast(widget.gptModuleStrings.pleaseEnterTextToGenerate);
      return;
    }

    hideKeyboard(context);
    isLoading = true;
    displayGeneratedText = false;
    isTextAnimationCompleted = false;
    setState(() {});

    await generateWithChatGPT(
      prompt: promptCont.text,
      promptPrefix: widget.promptPrefix,
      shortReply: widget.shortReply,
      testWithoutKey: widget.testWithoutKey,
      gptModuleStrings: widget.gptModuleStrings,
    ).then((value) async {
      answerCont.text = value.trim();

      await 350.milliseconds.delay;

      displayGeneratedText = true;
    }).catchError((e) {
      toast(e.toString());
    }).whenComplete(() {});

    isLoading = false;
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.height() * 0.96,
      margin: EdgeInsets.only(top: context.height() * 0.04),
      decoration: boxDecorationWithRoundedCorners(
        borderRadius:
            radiusOnly(topLeft: defaultRadius, topRight: defaultRadius),
        backgroundColor: context.cardColor,
      ),
      padding: EdgeInsets.only(right: 16, left: 16, bottom: 16, top: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${widget.gptModuleStrings.generateUsingAI} 🤖",
                  style: boldTextStyle(
                    size: 16,
                    color: context.platformBrightness() == Brightness.dark
                        ? whiteColor
                        : null,
                  ),
                ).expand(),
                CloseButton(color: context.iconColor),
              ],
            ),
            AppTextField(
              textFieldType: TextFieldType.MULTILINE,
              controller: promptCont,
              textStyle: primaryTextStyle(
                color: context.platformBrightness() == Brightness.dark
                    ? whiteColor
                    : null,
              ),
              decoration: widget.promptFieldInputDecoration ??
                  defaultInputDecoration(
                    hint: widget.gptModuleStrings.writeTextHere,
                    textStyle: secondaryTextStyle(
                      color: context.platformBrightness() == Brightness.dark
                          ? whiteColor
                          : null,
                    ),
                  ),
            ),
            32.height,
            Column(
              children: [
                AppButton(
                  child: isLoading
                      ? (widget.loaderWidget ??
                          Text(widget.gptModuleStrings.loading,
                              style: boldTextStyle(color: white)))
                      : Text(
                          answerCont.text.isNotEmpty
                              ? widget.gptModuleStrings.reGenerate
                              : widget.gptModuleStrings.generate,
                          style: boldTextStyle(color: white)),
                  color: context.primaryColor,
                  textStyle: boldTextStyle(color: white),
                  width: context.width(),
                  elevation: defaultAppButtonElevation,
                  onTap: () {
                    handleGenerateClick(context);
                  },
                ),
                if (displayGeneratedText)
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 20),
                        padding: EdgeInsets.all(8),
                        width: context.width(),
                        decoration: boxDecorationWithRoundedCorners(
                          borderRadius: radius(defaultRadius),
                          backgroundColor:
                              context.platformBrightness() == Brightness.dark
                                  ? context.cardColor
                                  : whiteColor,
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultTextStyle(
                              style: primaryTextStyle(
                                color: context.platformBrightness() ==
                                        Brightness.dark
                                    ? whiteColor
                                    : null,
                              ),
                              child: AnimatedTextKit(
                                repeatForever: false,
                                totalRepeatCount: 1,
                                isRepeatingAnimation: false,
                                onFinished: () {
                                  if (!isTextAnimationCompleted) {
                                    widget.recentList
                                        .insert(0, answerCont.text);
                                  }
                                  isTextAnimationCompleted = true;
                                  setState(() {});
                                },
                                animatedTexts: [
                                  TypewriterAnimatedText(
                                    answerCont.text,
                                    speed: Duration(
                                      milliseconds:
                                          isTextAnimationCompleted ? 0 : 30,
                                    ),
                                  ),
                                ],
                              ),
                            ).expand(),
                            if (isTextAnimationCompleted)
                              IconButton(
                                onPressed: () {
                                  answerCont.text.copyToClipboard();
                                  toast(widget.gptModuleStrings.copied);

                                  finish(context, answerCont.text);
                                },
                                icon: Icon(Icons.copy_outlined,
                                    color: context.iconColor, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                if (widget.recentList.isNotEmpty &&
                    widget.recentList.length > 1 &&
                    !isLoading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      8.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.gptModuleStrings.recent,
                            style: primaryTextStyle(
                              size: 16,
                              color: context.platformBrightness() ==
                                      Brightness.dark
                                  ? whiteColor
                                  : null,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.clear_all_rounded,
                                color: context.iconColor.withOpacity(0.6)),
                            onPressed: () async {
                              showConfirmDialogCustom(
                                context,
                                onAccept: (_) async {
                                  widget.recentList.clear();
                                  setState(() {});
                                },
                                primaryColor: context.primaryColor,
                                negativeText: widget.gptModuleStrings.no,
                                positiveText: widget.gptModuleStrings.yes,
                                title: widget
                                    .gptModuleStrings.doYouWantClearRecent,
                              );
                            },
                          ),
                        ],
                      ),
                      Container(
                        height: context.height() * 0.42,
                        child: AnimatedListView(
                          shrinkWrap: true,
                          itemCount: widget.recentList.take(6).length,
                          physics: NeverScrollableScrollPhysics(),
                          listAnimationType: ListAnimationType.FadeIn,
                          itemBuilder: (BuildContext context, int index) {
                            return GestureDetector(
                              onTap: () {
                                finish(context, widget.recentList[index]);
                              },
                              behavior: HitTestBehavior.translucent,
                              child: Container(
                                margin: EdgeInsets.only(bottom: 12),
                                padding: EdgeInsets.all(8),
                                decoration: boxDecorationWithRoundedCorners(
                                  borderRadius: radius(defaultRadius),
                                  backgroundColor: context
                                              .platformBrightness() ==
                                          Brightness.dark
                                      ? Colors.grey.shade200.withOpacity(0.1)
                                      : whiteColor,
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  widget.recentList[index],
                                  textAlign: TextAlign.left,
                                  style: secondaryTextStyle(
                                    size: 14,
                                    color: context.platformBrightness() ==
                                            Brightness.dark
                                        ? whiteColor
                                        : null,
                                  ),
                                  locale: Localizations.localeOf(context),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
