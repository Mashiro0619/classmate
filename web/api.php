<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| 配置区：只改这里
|--------------------------------------------------------------------------
*/
$relayUrl = 'https://api.deepseek.com/chat/completions';
$relayToken = 'your-deepseek-api-key';
$model = 'deepseek-chat';
$timeoutSeconds = 120;
$sourceByteLimit = 307200;
$maxParsesPerIpPerDay = 5;

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function respond(array $payload, int $status = 200): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function success(array $payload = []): void
{
    respond(['ok' => true] + $payload);
}

function error_response(string $message, int $status = 200): void
{
    respond(['ok' => false, 'message' => $message], $status);
}

function normalize_int_list(mixed $values): array
{
    if (!is_array($values)) {
        return [];
    }

    $result = [];
    foreach ($values as $value) {
        $intValue = (int) $value;
        if ($intValue > 0) {
            $result[] = $intValue;
        }
    }

    $result = array_values(array_unique($result));
    sort($result);
    return $result;
}

function sanitize_source_content(string $content): string
{
    return trim($content);
}

function get_client_ip(): string
{
    $keys = ['HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR'];
    foreach ($keys as $key) {
        $value = trim((string) ($_SERVER[$key] ?? ''));
        if ($value === '') {
            continue;
        }
        if ($key === 'HTTP_X_FORWARDED_FOR') {
            $parts = array_map('trim', explode(',', $value));
            $value = (string) ($parts[0] ?? '');
        }
        if ($value !== '') {
            return $value;
        }
    }
    return 'unknown';
}

function get_rate_limit_file_path(string $ip): string
{
    $safeIp = preg_replace('/[^a-zA-Z0-9_.:-]/', '_', $ip) ?: 'unknown';
    return sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'classmate_import_rate_' . date('Ymd') . '_' . $safeIp . '.json';
}

function assert_rate_limit(string $ip, int $maxParsesPerDay): void
{
    $path = get_rate_limit_file_path($ip);
    $count = 0;
    if (is_file($path)) {
        $decoded = json_decode((string) file_get_contents($path), true);
        if (is_array($decoded)) {
            $count = (int) ($decoded['count'] ?? 0);
        }
    }
    if ($count >= $maxParsesPerDay) {
        throw new RuntimeException('Daily parse limit reached for this IP.');
    }
    file_put_contents(
        $path,
        json_encode(['count' => $count + 1], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
        LOCK_EX,
    );
}

function decode_json_object(string $text): ?array
{
    $trimmed = trim($text);
    if ($trimmed === '') {
        return null;
    }

    $decoded = json_decode($trimmed, true);
    if (is_array($decoded)) {
        return $decoded;
    }

    if (preg_match('/```(?:json)?\s*([\s\S]*?)\s*```/iu', $trimmed, $matches) === 1) {
        $decoded = json_decode(trim($matches[1]), true);
        if (is_array($decoded)) {
            return $decoded;
        }
    }

    $start = strpos($trimmed, '{');
    $end = strrpos($trimmed, '}');
    if ($start === false || $end === false || $end <= $start) {
        return null;
    }

    $decoded = json_decode(substr($trimmed, $start, $end - $start + 1), true);
    return is_array($decoded) ? $decoded : null;
}

function extract_text_content(mixed $content): string
{
    if (is_string($content)) {
        return $content;
    }

    if (!is_array($content)) {
        return '';
    }

    $parts = [];
    foreach ($content as $item) {
        if (is_array($item) && isset($item['text']) && is_string($item['text'])) {
            $parts[] = $item['text'];
        }
    }

    return implode("\n", $parts);
}

function normalize_payload(array $payload): array
{
    $timetable = $payload['timetable'] ?? $payload;
    if (!is_array($timetable)) {
        throw new InvalidArgumentException('AI returned an invalid timetable object.');
    }

    $periodSet = $timetable['periodTimeSet'] ?? [];
    $periodTimes = [];
    foreach (($periodSet['periodTimes'] ?? []) as $index => $item) {
        if (!is_array($item)) {
            continue;
        }

        $start = (int) ($item['startMinutes'] ?? 0);
        $end = (int) ($item['endMinutes'] ?? 0);
        if ($start < 0 || $end <= $start) {
            continue;
        }

        $periodTimes[] = [
            'index' => max(1, (int) ($item['index'] ?? ($index + 1))),
            'startMinutes' => $start,
            'endMinutes' => $end,
        ];
    }

    usort($periodTimes, static fn(array $a, array $b): int => $a['index'] <=> $b['index']);

    $courses = [];
    foreach (($timetable['courses'] ?? []) as $course) {
        if (!is_array($course)) {
            continue;
        }

        $name = trim((string) ($course['name'] ?? ''));
        if ($name === '') {
            continue;
        }

        $periods = normalize_int_list($course['periods'] ?? []);
        $semesterWeeks = normalize_int_list($course['semesterWeeks'] ?? []);
        $start = (int) ($course['startMinutes'] ?? 0);
        $end = (int) ($course['endMinutes'] ?? 0);
        if ($start < 0 || $end < 0) {
            continue;
        }

        if ($end <= $start) {
            $start = 0;
            $end = 0;
        }

        $courses[] = [
            'name' => $name,
            'teacher' => trim((string) ($course['teacher'] ?? '')),
            'location' => trim((string) ($course['location'] ?? '')),
            'dayOfWeek' => max(1, min(7, (int) ($course['dayOfWeek'] ?? 1))),
            'semesterWeeks' => $semesterWeeks,
            'periods' => $periods,
            'startMinutes' => $start,
            'endMinutes' => $end,
            'credit' => (float) ($course['credit'] ?? 0),
            'remarks' => trim((string) ($course['remarks'] ?? '')),
            'customFields' => is_array($course['customFields'] ?? null)
                ? $course['customFields']
                : new stdClass(),
        ];
    }

    if ($courses === []) {
        throw new InvalidArgumentException('No importable courses were found in the AI result.');
    }

    return [
        'name' => trim((string) ($timetable['name'] ?? '')),
        'startDate' => (string) ($timetable['startDate'] ?? date('Y-m-d')),
        'totalWeeks' => max(1, min(100, (int) ($timetable['totalWeeks'] ?? 18))),
        'periodTimeSet' => [
            'name' => trim((string) ($periodSet['name'] ?? 'Imported periods')),
            'periodTimes' => $periodTimes,
        ],
        'courses' => $courses,
    ];
}

$action = trim((string) ($_GET['action'] ?? ''));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

if ($action === '') {
    success([
        'message' => 'School import API is running.',
    ]);
}

if ($action !== 'import_timetable') {
    error_response('Unsupported action.', 400);
}

if ($method !== 'POST') {
    error_response('POST method required.', 405);
}

$rawBody = file_get_contents('php://input');
$body = json_decode($rawBody ?: '{}', true);
if (!is_array($body)) {
    error_response('Request body must be a JSON object.', 400);
}

try {
    if (trim($relayUrl) === '' || trim($relayToken) === '') {
        throw new RuntimeException('Relay configuration is missing.');
    }

    $url = trim((string) ($body['url'] ?? ''));
    $title = trim((string) ($body['title'] ?? ''));
    $locale = trim((string) ($body['locale'] ?? ''));
    $sourceHint = trim((string) ($body['sourceHint'] ?? ''));
    $sourceContent = trim((string) ($body['html'] ?? ($body['content'] ?? '')));

    if ($sourceContent === '') {
        throw new InvalidArgumentException('Page content is missing.');
    }
    if (strlen($sourceContent) > $sourceByteLimit) {
        throw new InvalidArgumentException('Page content exceeds 300KB.');
    }

    $cleanSourceContent = sanitize_source_content($sourceContent);
    if ($cleanSourceContent === '') {
        throw new InvalidArgumentException('Page content is empty after sanitization.');
    }

    $clientIp = get_client_ip();
    assert_rate_limit($clientIp, $maxParsesPerIpPerDay);

    $systemPrompt = <<<'PROMPT'
You are an expert timetable extraction engine.

Your job is to read the provided page content and convert it into exactly one JSON object.
The content may be HTML, plain text, copied table text, JSON fragments, or mixed page source.
Return JSON only. Do not wrap it in markdown. Do not add explanations.

The JSON schema must be exactly:
{
  "name": "string",
  "startDate": "YYYY-MM-DD",
  "totalWeeks": 18,
  "periodTimeSet": {
    "name": "string",
    "periodTimes": [
      {"index": 1, "startMinutes": 480, "endMinutes": 525}
    ]
  },
  "courses": [
    {
      "name": "string",
      "teacher": "string",
      "location": "string",
      "dayOfWeek": 1,
      "semesterWeeks": [1, 2, 3],
      "periods": [1, 2],
      "startMinutes": 480,
      "endMinutes": 570,
      "credit": 0,
      "remarks": "string",
      "customFields": {}
    }
  ]
}

Rules:
1. Extract the actual timetable from the provided content. Ignore navigation, scripts, styles, ads, and unrelated text.
2. The source content is not guaranteed to be valid HTML. You must still try to recognize timetable information from any text or mixed markup.
3. Output one valid JSON object only.
4. Use empty strings instead of null.
5. Use [] instead of null for arrays.
6. Use {} instead of null for customFields.
7. dayOfWeek uses Monday=1 through Sunday=7.
8. semesterWeeks and periods must contain positive integers only, sorted ascending, without duplicates.
9. startMinutes and endMinutes must be integers representing minutes after 00:00 when the source explicitly provides real class times; otherwise use 0.
10. Never invent period times, startMinutes, endMinutes, or a periodTimeSet when the source does not explicitly provide them.
11. If the content contains period numbers but not explicit times, keep periods only and leave time-related fields as 0; keep periodTimeSet.periodTimes as an empty array.
12. If the content contains explicit class times, preserve them exactly.
13. Only fill periodTimeSet.periodTimes when the source explicitly provides actual period time ranges.
14. If a field is unknown, keep it empty or 0, but still keep the field.
15. If the timetable title is visible, put it in name.
16. If the total week count is not visible, use 18.
17. If the start date is not visible, use the best reasonable YYYY-MM-DD value from the context; if unavailable, use today's date.
18. Only include real courses that appear in the provided content.
PROMPT;

    $userPayload = [
        'url' => $url,
        'title' => $title,
        'locale' => $locale,
        'sourceHint' => $sourceHint,
        'content' => $cleanSourceContent,
    ];

    $relayPayload = [
        'model' => $model,
        'messages' => [
            [
                'role' => 'system',
                'content' => $systemPrompt,
            ],
            [
                'role' => 'user',
                'content' => json_encode($userPayload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            ],
        ],
        'stream' => false,
        'temperature' => 0.1,
    ];

    $ch = curl_init($relayUrl);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Authorization: Bearer ' . $relayToken,
        ],
        CURLOPT_POSTFIELDS => json_encode($relayPayload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
        CURLOPT_CONNECTTIMEOUT => 15,
        CURLOPT_TIMEOUT => $timeoutSeconds,
    ]);

    $raw = curl_exec($ch);
    $status = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    if ($raw === false || $raw === '') {
        $detail = $curlError !== '' ? $curlError : 'empty response';
        throw new RuntimeException('Relay request failed: ' . $detail);
    }

    if ($status < 200 || $status >= 300) {
        throw new RuntimeException('Relay request failed (' . $status . '): ' . mb_substr((string) $raw, 0, 1000, 'UTF-8'));
    }

    $relayJson = json_decode((string) $raw, true);
    if (!is_array($relayJson)) {
        throw new RuntimeException('Relay returned invalid JSON: ' . mb_substr((string) $raw, 0, 1000, 'UTF-8'));
    }

    $content = $relayJson['choices'][0]['message']['content']
        ?? $relayJson['message']['content']
        ?? $relayJson['content']
        ?? '';

    $contentText = trim(extract_text_content($content));
    if ($contentText === '') {
        throw new RuntimeException('Relay returned empty content: ' . mb_substr((string) $raw, 0, 1000, 'UTF-8'));
    }

    $schedule = decode_json_object($contentText);
    if (!is_array($schedule)) {
        throw new RuntimeException('AI content is not valid timetable JSON: ' . mb_substr($contentText, 0, 1000, 'UTF-8'));
    }

    $normalized = normalize_payload($schedule);

    success([
        'meta' => [
            'sourceUrl' => $url,
            'pageTitle' => $title,
            'parser' => 'deepseek_html',
            'warnings' => [],
        ],
        'timetable' => $normalized,
    ]);
} catch (InvalidArgumentException $error) {
    error_response($error->getMessage(), 400);
} catch (RuntimeException $error) {
    error_response($error->getMessage(), 200);
} catch (Throwable $error) {
    error_response('Unexpected server error: ' . $error->getMessage(), 200);
}
