enum DialogueActionKind { next, close, alt, quest }

class DialogueAction {
  final String label;
  final DialogueActionKind kind;
  const DialogueAction(this.label, this.kind);
}

class DialogueNode {
  final String text;
  final List<DialogueAction> actions;
  const DialogueNode(this.text, this.actions);
}

/// 사서 모루's branching greeting — verbatim from the Claude Design
/// prototype's `DIALOGUE` array.
const List<DialogueNode> kLibrarianDialogue = [
  DialogueNode(
    '어서 와요. 3층은 아직 정리가 덜 됐지만… 오늘 당신한테 맞을 책은 이미 골라뒀어요.',
    [
      DialogueAction('어떤 책인데요?', DialogueActionKind.next),
      DialogueAction('오늘은 그냥 걸을게요', DialogueActionKind.close),
    ],
  ),
  DialogueNode(
    'SF 서가 두 번째 칸, 「우주보다 작은 것들」. 짧고 조용한 책이에요. 다 읽고 나면 감상문 한 장 남겨주면 좋겠는데.',
    [
      DialogueAction('찾아볼게요', DialogueActionKind.quest),
      DialogueAction('다른 추천도 있어요?', DialogueActionKind.alt),
    ],
  ),
  DialogueNode(
    '그럼 「밀물 관찰기」. 신간 코너에 두었어요. 이쪽은 친구들과 같이 읽기 좋은 책이고요.',
    [
      DialogueAction('고마워요', DialogueActionKind.close),
      DialogueAction('SF 쪽으로 할게요', DialogueActionKind.quest),
    ],
  ),
];
