const { OpenAI } = require('openai');

let client = null;

// Lazy init: `new OpenAI()` throws without an API key, which used to crash the
// whole server on startup even if AI features were never used.
function getClient() {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey || apiKey.startsWith('sk-your')) {
    const err = new Error('OPENAI_API_KEY is not configured');
    err.code = 'AI_NOT_CONFIGURED';
    throw err;
  }
  if (!client) client = new OpenAI({ apiKey });
  return client;
}

// Extracts the first JSON object from the model answer.
function parseJson(content) {
  const match = (content || '').match(/\{[\s\S]*\}/);
  if (!match) throw new Error('AI response does not contain JSON');
  return JSON.parse(match[0]);
}

async function askJson({ system, prompt, temperature, maxTokens, label }) {
  try {
    const response = await getClient().chat.completions.create(
      {
        model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: prompt },
        ],
        temperature,
        max_tokens: maxTokens,
      },
      { timeout: Number(process.env.AI_TIMEOUT_MS) || 60000 }
    );
    return parseJson(response.choices[0].message.content);
  } catch (error) {
    if (error.code === 'AI_NOT_CONFIGURED') throw error;
    console.error(`AI ${label} Error:`, error.message);
    const wrapped = new Error(`Failed to ${label}`);
    if (error.name === 'APIConnectionTimeoutError' || error.code === 'ETIMEDOUT') {
      wrapped.code = 'AI_TIMEOUT';
    }
    throw wrapped;
  }
}

class AIService {
  /**
   * Генерирует учебный план на основе цели и предмета
   */
  generateStudyPlan(goal, subject, currentLevel, deadline) {
    return askJson({
      label: 'generate study plan',
      system: 'Ты опытный преподаватель и образовательный консультант. Всегда отвечай на русском языке.',
      temperature: 0.7,
      maxTokens: 2000,
      prompt: `
        Создай детальный учебный план для студента со следующими параметрами:
        - Цель: ${goal}
        - Предмет: ${subject}
        - Текущий уровень: ${currentLevel}
        - Дедлайн: ${deadline} дней

        Формат ответа - JSON с полями:
        {
          "title": "название плана",
          "duration_days": число,
          "weeks": [
            {
              "week": число,
              "topics": ["тема1", "тема2"],
              "daily_hours": число,
              "resources": ["ресурс1", "ресурс2"],
              "milestones": ["веха1"]
            }
          ],
          "tips": ["совет1", "совет2"]
        }
      `,
    });
  }

  /**
   * Анализирует статистику учебы и дает рекомендации
   */
  analyzeStudyStats(statsData) {
    return askJson({
      label: 'analyze study stats',
      system: 'Ты экспертный образовательный аналитик. Дай честный, конструктивный анализ. Ответ на русском.',
      temperature: 0.6,
      maxTokens: 1500,
      prompt: `
        Проанализируй следующую статистику учебы студента и дай рекомендации:

        ${JSON.stringify(statsData, null, 2)}

        Предоставь анализ в формате JSON:
        {
          "summary": "краткое резюме",
          "strengths": ["сильная сторона1", "сильная сторона2"],
          "weaknesses": ["слабая сторона1", "слабая сторона2"],
          "recommendations": ["рекомендация1", "рекомендация2"],
          "motivation_tips": ["совет1", "совет2"],
          "predicted_progress": "прогноз прогресса"
        }
      `,
    });
  }

  /**
   * Проверяет работу студента и дает рекомендации
   */
  reviewStudentWork(workType, workContent, subject, level) {
    return askJson({
      label: 'review work',
      system: 'Ты опытный учитель и эксперт в оценке студенческих работ. Будь конструктивным и поддерживающим. Ответ на русском.',
      temperature: 0.5,
      maxTokens: 2000,
      prompt: `
        Проверь работу студента и дай подробный отзыв:

        Тип работы: ${workType}
        Предмет: ${subject}
        Уровень: ${level}

        Содержание работы:
        ${workContent}

        Предоставь отзыв в формате JSON:
        {
          "overall_score": число от 1 до 10,
          "strengths": ["сильная сторона1", "сильная сторона2"],
          "areas_for_improvement": ["улучшение1", "улучшение2"],
          "detailed_feedback": "подробный отзыв",
          "suggested_resources": ["ресурс1", "ресурс2"],
          "next_steps": ["шаг1", "шаг2"]
        }
      `,
    });
  }

  /**
   * Генерирует мотивационные цитаты
   */
  generateMotivationalQuote(userGoal, subject) {
    return askJson({
      label: 'generate quote',
      system: 'Ты мотивационный коуч. Создавай искренние, вдохновляющие цитаты. Ответ на русском.',
      temperature: 0.8,
      maxTokens: 500,
      prompt: `
        Создай вдохновляющую и мотивирующую цитату для студента:
        - Цель: ${userGoal}
        - Предмет: ${subject}

        Ответ должен быть в формате JSON:
        {
          "quote": "сама цитата",
          "author": "автор (или 'Unknown' если нет)",
          "context": "контекст для студента",
          "action_point": "конкретное действие для мотивации"
        }
      `,
    });
  }

  /**
   * Рекомендует ресурсы на основе целей и предмета
   */
  recommendResources(goal, subject, level, interests) {
    return askJson({
      label: 'recommend resources',
      system: 'Ты эксперт по образовательным ресурсам. Рекомендуй только лучшие, проверенные материалы. Ответ на русском.',
      temperature: 0.7,
      maxTokens: 2500,
      prompt: `
        Рекомендуй лучшие ресурсы для обучения:
        - Цель: ${goal}
        - Предмет: ${subject}
        - Уровень: ${level}
        - Интересы: ${interests}

        Формат JSON:
        {
          "books": [{"title": "название", "author": "автор", "why": "почему полезна"}],
          "online_courses": [{"name": "название", "platform": "платформа", "duration": "длительность"}],
          "youtube_channels": [{"name": "канал", "description": "описание"}],
          "websites": [{"name": "название", "url_format": "пример URL"}],
          "tools": [{"name": "инструмент", "purpose": "назначение"}]
        }
      `,
    });
  }

  /**
   * Создает персональные рекомендации на основе прогресса
   */
  getPersonalizedRecommendations(userData) {
    return askJson({
      label: 'get recommendations',
      system: 'Ты личный образовательный тренер. Дай конкретные, персональные рекомендации. Ответ на русском.',
      temperature: 0.7,
      maxTokens: 1500,
      prompt: `
        На основе профиля студента дай персональные рекомендации:

        ${JSON.stringify(userData, null, 2)}

        Ответь в JSON:
        {
          "immediate_actions": ["действие1", "действие2"],
          "weekly_focus": "на чем сосредоточиться на неделе",
          "habit_changes": ["новая привычка1", "новая привычка2"],
          "time_optimization": "как оптимизировать время учебы",
          "motivation_strategy": "стратегия мотивации"
        }
      `,
    });
  }
}

module.exports = new AIService();
