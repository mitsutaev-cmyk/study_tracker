const { OpenAI } = require('openai');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

class AIService {
  /**
   * Генерирует учебный план на основе цели и предмета
   */
  async generateStudyPlan(goal, subject, currentLevel, deadline) {
    try {
      const prompt = `
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
      `;

      const response = await openai.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'Ты опытный преподаватель и образовательный консультант. Всегда отвечай на русском языке.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.7,
        max_tokens: 2000,
      });

      const content = response.choices[0].message.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      return jsonMatch ? JSON.parse(jsonMatch[0]) : { error: 'Failed to parse plan' };
    } catch (error) {
      console.error('AI Study Plan Error:', error);
      throw new Error('Failed to generate study plan');
    }
  }

  /**
   * Анализирует статистику учебы и дает рекомендации
   */
  async analyzeStudyStats(statsData) {
    try {
      const prompt = `
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
      `;

      const response = await openai.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'Ты экспертный образовательный аналитик. Дай честный, конструктивный анализ. Ответ на русском.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.6,
        max_tokens: 1500,
      });

      const content = response.choices[0].message.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      return jsonMatch ? JSON.parse(jsonMatch[0]) : { error: 'Failed to parse analysis' };
    } catch (error) {
      console.error('AI Analysis Error:', error);
      throw new Error('Failed to analyze study stats');
    }
  }

  /**
   * Проверяет работу студента и дает рекомендации
   */
  async reviewStudentWork(workType, workContent, subject, level) {
    try {
      const prompt = `
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
      `;

      const response = await openai.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'Ты опытный учитель и эксперт в оценке студенческих работ. Будь конструктивным и поддерживающим. Ответ на русском.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.5,
        max_tokens: 2000,
      });

      const content = response.choices[0].message.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      return jsonMatch ? JSON.parse(jsonMatch[0]) : { error: 'Failed to parse review' };
    } catch (error) {
      console.error('AI Review Error:', error);
      throw new Error('Failed to review work');
    }
  }

  /**
   * Генерирует мотивационные цитаты
   */
  async generateMotivationalQuote(userGoal, subject) {
    try {
      const prompt = `
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
      `;

      const response = await openai.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'Ты мотивационный коуч. Создавай искренние, вдохновляющие цитаты. Ответ на русском.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.8,
        max_tokens: 500,
      });

      const content = response.choices[0].message.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      return jsonMatch ? JSON.parse(jsonMatch[0]) : { error: 'Failed to parse quote' };
    } catch (error) {
      console.error('AI Quote Error:', error);
      throw new Error('Failed to generate quote');
    }
  }

  /**
   * Рекомендует ресурсы на основе целей и предмета
   */
  async recommendResources(goal, subject, level, interests) {
    try {
      const prompt = `
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
      `;

      const response = await openai.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'Ты эксперт по образовательным ресурсам. Рекомендуй только лучшие, проверенные материалы. Ответ на русском.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.7,
        max_tokens: 2500,
      });

      const content = response.choices[0].message.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      return jsonMatch ? JSON.parse(jsonMatch[0]) : { error: 'Failed to parse resources' };
    } catch (error) {
      console.error('AI Resources Error:', error);
      throw new Error('Failed to recommend resources');
    }
  }

  /**
   * Создает персональные рекомендации на основе прогресса
   */
  async getPersonalizedRecommendations(userData) {
    try {
      const prompt = `
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
      `;

      const response = await openai.chat.completions.create({
        model: process.env.OPENAI_MODEL || 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'Ты личный образовательный тренер. Дай конкретные, персональные рекомендации. Ответ на русском.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.7,
        max_tokens: 1500,
      });

      const content = response.choices[0].message.content;
      const jsonMatch = content.match(/\{[\s\S]*\}/);
      return jsonMatch ? JSON.parse(jsonMatch[0]) : { error: 'Failed to parse recommendations' };
    } catch (error) {
      console.error('AI Recommendations Error:', error);
      throw new Error('Failed to get recommendations');
    }
  }
}

module.exports = new AIService();