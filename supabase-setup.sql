-- Your Life App - Supabase Database Setup
-- Run this entire script in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- TASKS
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  notes TEXT,
  life_area TEXT,
  scheduled_date DATE,
  time_estimate TEXT,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  recurring TEXT DEFAULT 'none',
  recurring_day INTEGER,
  recurring_date INTEGER,
  project_id UUID,
  parent_task_id UUID,
  reschedule_count INTEGER DEFAULT 0,
  google_calendar_event_id TEXT,
  someday BOOLEAN DEFAULT FALSE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- GOALS
CREATE TABLE IF NOT EXISTS goals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  life_area TEXT,
  target_date DATE,
  notes TEXT,
  status TEXT DEFAULT 'active',
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- PROJECTS
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  life_area TEXT,
  description TEXT,
  status TEXT DEFAULT 'active',
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- HABITS (daily practice check-ins)
CREATE TABLE IF NOT EXISTS habits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  practice_index INTEGER NOT NULL,
  completed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date, practice_index)
);

-- IDEAS (Idea Vault)
CREATE TABLE IF NOT EXISTS ideas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  life_area TEXT,
  status TEXT DEFAULT 'seeds',
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- DAILY STATE
CREATE TABLE IF NOT EXISTS daily_state (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  date DATE NOT NULL,
  energy INTEGER,
  priority1 TEXT,
  priority2 TEXT,
  priority3 TEXT,
  intention TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- WEEKLY REFLECTIONS
CREATE TABLE IF NOT EXISTS weekly_reflections (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  week_start DATE NOT NULL,
  reflection TEXT,
  practice_stats JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, week_start)
);

-- USER PREFERENCES
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  theme TEXT DEFAULT 'system',
  google_calendar_connected BOOLEAN DEFAULT FALSE,
  google_tokens JSONB,
  area_focus JSONB DEFAULT '{}',
  notification_prefs JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- INDEXES for performance
CREATE INDEX IF NOT EXISTS tasks_user_date ON tasks(user_id, scheduled_date);
CREATE INDEX IF NOT EXISTS tasks_user_project ON tasks(user_id, project_id);
CREATE INDEX IF NOT EXISTS habits_user_date ON habits(user_id, date);
CREATE INDEX IF NOT EXISTS ideas_user_area ON ideas(user_id, life_area);
CREATE INDEX IF NOT EXISTS daily_state_user_date ON daily_state(user_id, date);

-- ROW LEVEL SECURITY (very important!)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;
ALTER TABLE ideas ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE weekly_reflections ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- RLS POLICIES - users can only see their own data
CREATE POLICY "Users own tasks" ON tasks FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own goals" ON goals FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own projects" ON projects FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own habits" ON habits FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own ideas" ON ideas FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own daily_state" ON daily_state FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own weekly_reflections" ON weekly_reflections FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users own preferences" ON user_preferences FOR ALL USING (auth.uid() = user_id);

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers
CREATE TRIGGER tasks_updated_at BEFORE UPDATE ON tasks FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER goals_updated_at BEFORE UPDATE ON goals FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER projects_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER ideas_updated_at BEFORE UPDATE ON ideas FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER daily_state_updated_at BEFORE UPDATE ON daily_state FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER user_preferences_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at();
