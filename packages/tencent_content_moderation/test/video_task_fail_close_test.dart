import 'package:tencent_content_moderation/tencent_content_moderation.dart';
import 'package:test/test.dart';

void main() {
  group('视频失败关闭 helper', () {
    const passHit = ModerationHit(
      decision: ModerationDecision.pass,
      label: ModerationLabel(name: 'Normal'),
    );
    const reviewHit = ModerationHit(
      decision: ModerationDecision.review,
      label: ModerationLabel(name: 'Porn'),
    );
    const blockHit = ModerationHit(
      decision: ModerationDecision.block,
      label: ModerationLabel(name: 'Terror'),
    );

    final rows = <_CloseRow>[
      _CloseRow(
        name: 'cancelled 且建议为 pass 时关闭为 block',
        status: ModerationTaskStatus.cancelled,
        payload: const {'Status': 'CANCELLED', 'Suggestion': 'Pass'},
        failed: true,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.block,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.block],
      ),
      _CloseRow(
        name: 'FINISH 且带 ErrorType 时关闭为 block',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'ErrorType': 'DECODE_ERROR',
        },
        failed: true,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.block,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.block],
      ),
      _CloseRow(
        name: 'FINISH 且带 ErrorDescription 时关闭为 block',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'ErrorDescription': 'download failed',
        },
        failed: true,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.block,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.block],
      ),
      _CloseRow(
        name: 'Errors 的 Code 为 URL_ERROR 时关闭为 block',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'Errors': [
            {'Code': 'URL_ERROR', 'Message': '403 Forbidden'},
          ],
        },
        failed: true,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.block,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.block],
      ),
      _CloseRow(
        name: '错误字段嵌在 Task 里时关闭为 block',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Task': {
            'Status': 'FINISH',
            'Suggestion': 'Pass',
            'ErrorType': 'URL_ERROR',
          },
        },
        failed: true,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.block,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.block],
      ),
      _CloseRow(
        name: 'ErrorDescription 为空时不关闭',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'ErrorDescription': '',
        },
        failed: false,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.pass,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.pass],
      ),
      _CloseRow(
        name: 'ErrorDescription 只有空白时不关闭',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'ErrorDescription': ' \t\n ',
        },
        failed: false,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.pass,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.pass],
      ),
      _CloseRow(
        name: '失败状态的复审必须改为拦截',
        status: ModerationTaskStatus.error,
        payload: const {'Status': 'ERROR', 'ErrorType': 'URL_ERROR'},
        failed: true,
        inputDecision: ModerationDecision.review,
        expectedDecision: ModerationDecision.block,
        hits: const [reviewHit],
        expectedHitDecisions: const [ModerationDecision.block],
      ),
      _CloseRow(
        name: '完成态复审且带结构化错误时关闭为 block',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Review',
          'ErrorType': 'DECODE_ERROR',
        },
        failed: true,
        inputDecision: ModerationDecision.review,
        expectedDecision: ModerationDecision.block,
        hits: const [reviewHit, passHit],
        expectedHitDecisions: const [
          ModerationDecision.block,
          ModerationDecision.block,
        ],
      ),
      _CloseRow(
        name: '完成态复审且没有结构化错误时保持复审',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Review',
        },
        failed: false,
        inputDecision: ModerationDecision.review,
        expectedDecision: ModerationDecision.review,
        hits: const [reviewHit],
        expectedHitDecisions: const [ModerationDecision.review],
      ),
      _CloseRow(
        name: '进行中复审且带结构化错误时关闭为 block',
        status: ModerationTaskStatus.running,
        payload: const {
          'Status': 'RUNNING',
          'Suggestion': 'Review',
          'ErrorType': 'URL_ERROR',
        },
        failed: true,
        inputDecision: ModerationDecision.review,
        expectedDecision: ModerationDecision.block,
        hits: const [reviewHit],
        expectedHitDecisions: const [ModerationDecision.block],
      ),
      _CloseRow(
        name: '进行中且没有结构化错误时建议通过仍为 pass',
        status: ModerationTaskStatus.running,
        payload: const {
          'Status': 'RUNNING',
          'Suggestion': 'Pass',
        },
        failed: false,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.pass,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.pass],
      ),
      _CloseRow(
        name: '失败时 block 不被改写',
        status: ModerationTaskStatus.cancelled,
        payload: const {'Status': 'CANCELLED', 'Suggestion': 'Block'},
        failed: true,
        inputDecision: ModerationDecision.block,
        expectedDecision: ModerationDecision.block,
        hits: const [blockHit],
        expectedHitDecisions: const [ModerationDecision.block],
      ),
      _CloseRow(
        name: '失败时空建议不被改写',
        status: ModerationTaskStatus.error,
        payload: const {'Status': 'ERROR'},
        failed: true,
        expectedDecision: null,
        hits: const [],
        expectedHitDecisions: const [],
      ),
      _CloseRow(
        name: '失败时命中明细的 pass 与 review 都改成 block',
        status: ModerationTaskStatus.error,
        payload: const {'Status': 'FAILED', 'Suggestion': 'Pass'},
        failed: true,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.block,
        hits: const [passHit, reviewHit, blockHit],
        expectedHitDecisions: const [
          ModerationDecision.block,
          ModerationDecision.block,
          ModerationDecision.block,
        ],
      ),
      _CloseRow(
        name: '结构化错误：Errors 的 Code 不是 URL_ERROR 时也关闭',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'Errors': [
            {'Code': 'DECODE_ERROR', 'Message': 'bad media'},
          ],
        },
        failed: true,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.block,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.block],
      ),
      _CloseRow(
        name: '结构化错误：正文仅含 URL_ERROR 子串时不关闭',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'AsrText': '旁白里出现 URL_ERROR 这个词',
          'OcrResults': [
            {'Text': '画面文字 URL_ERROR'},
          ],
          'AudioSegments': [
            {'Text': '字幕 URL_ERROR'},
          ],
        },
        failed: false,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.pass,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.pass],
      ),
      _CloseRow(
        name: '结构化错误：ErrorType 只有空白时不关闭',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'ErrorType': ' \t ',
        },
        failed: false,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.pass,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.pass],
      ),
      _CloseRow(
        name: '结构化错误：Errors 的 Code 只有空白且说明里有 URL_ERROR 时不关闭',
        status: ModerationTaskStatus.finish,
        payload: const {
          'Status': 'FINISH',
          'Suggestion': 'Pass',
          'Errors': [
            {'Code': '  ', 'Message': 'URL_ERROR'},
          ],
        },
        failed: false,
        inputDecision: ModerationDecision.pass,
        expectedDecision: ModerationDecision.pass,
        hits: const [passHit],
        expectedHitDecisions: const [ModerationDecision.pass],
      ),
    ];

    for (final row in rows) {
      test(row.name, () {
        final failed = videoTaskFailed(
          status: row.status,
          payload: row.payload,
          extra: row.extra,
        );
        expect(failed, row.failed, reason: row.name);
        expect(
          closedVideoDecision(
            status: row.status,
            decision: row.inputDecision,
            payload: row.payload,
            extra: row.extra,
          ),
          row.expectedDecision,
          reason: row.name,
        );

        final hits = closedVideoHits(row.hits, failed: failed);
        expect(
          hits.map((hit) => hit.decision).toList(),
          row.expectedHitDecisions,
          reason: row.name,
        );
        if (failed) {
          expect(
            hits.map((hit) => hit.decision),
            isNot(contains(ModerationDecision.pass)),
            reason: row.name,
          );
          expect(
            hits.map((hit) => hit.decision),
            isNot(contains(ModerationDecision.review)),
            reason: row.name,
          );
        }
        for (var i = 0; i < row.hits.length; i++) {
          final original = row.hits[i];
          final keep = !failed ||
              (original.decision != ModerationDecision.pass &&
                  original.decision != ModerationDecision.review);
          if (keep) {
            expect(identical(hits[i], original), isTrue, reason: row.name);
          } else {
            expect(hits[i].decision, ModerationDecision.block,
                reason: row.name);
            expect(identical(hits[i], original), isFalse, reason: row.name);
          }
        }
      });
    }
  });
}

class _CloseRow {
  final String name;
  final ModerationTaskStatus status;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic>? extra;
  final bool failed;
  final ModerationDecision? inputDecision;
  final ModerationDecision? expectedDecision;
  final List<ModerationHit> hits;
  final List<ModerationDecision> expectedHitDecisions;

  const _CloseRow({
    required this.name,
    required this.status,
    required this.failed,
    required this.expectedDecision,
    required this.hits,
    required this.expectedHitDecisions,
    this.payload,
    this.extra,
    this.inputDecision,
  });
}
