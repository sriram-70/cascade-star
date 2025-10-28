-- Create enum for user roles
CREATE TYPE public.app_role AS ENUM ('ceo', 'growth_head', 'fulfillment_head', 'support_head', 'metric_owner');

-- Create enum for metric categories
CREATE TYPE public.metric_category AS ENUM ('hero', 'growth', 'fulfillment', 'support');

-- Create enum for scorecard status
CREATE TYPE public.scorecard_status AS ENUM ('locked', 'active', 'archived');

-- Organizations table
CREATE TABLE public.organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  ceo_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User roles table (separate from profiles for security)
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
  role public.app_role NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, organization_id)
);

-- Profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Departments table
CREATE TABLE public.departments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
  engine_head_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  engine_type TEXT NOT NULL CHECK (engine_type IN ('growth', 'fulfillment', 'support')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Scorecards table
CREATE TABLE public.scorecards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
  owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL,
  status public.scorecard_status NOT NULL DEFAULT 'locked',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Metrics table
CREATE TABLE public.metrics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  category public.metric_category NOT NULL,
  target_value NUMERIC,
  current_value NUMERIC DEFAULT 0,
  unit TEXT,
  owner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  department_id UUID REFERENCES public.departments(id) ON DELETE CASCADE,
  organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scorecards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.metrics ENABLE ROW LEVEL SECURITY;

-- Security definer function to check user role
CREATE OR REPLACE FUNCTION public.has_role(_user_id UUID, _org_id UUID, _role public.app_role)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND organization_id = _org_id
      AND role = _role
  )
$$;

-- Security definer function to check if user belongs to organization
CREATE OR REPLACE FUNCTION public.belongs_to_org(_user_id UUID, _org_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles
    WHERE user_id = _user_id
      AND organization_id = _org_id
  )
$$;

-- RLS Policies for organizations
CREATE POLICY "Users can view their own organization"
  ON public.organizations FOR SELECT
  USING (public.belongs_to_org(auth.uid(), id));

CREATE POLICY "CEOs can create organizations"
  ON public.organizations FOR INSERT
  WITH CHECK (auth.uid() = ceo_id);

CREATE POLICY "CEOs can update their organizations"
  ON public.organizations FOR UPDATE
  USING (auth.uid() = ceo_id);

-- RLS Policies for user_roles
CREATE POLICY "Users can view roles in their organization"
  ON public.user_roles FOR SELECT
  USING (public.belongs_to_org(auth.uid(), organization_id));

CREATE POLICY "CEOs can manage roles in their organization"
  ON public.user_roles FOR ALL
  USING (public.has_role(auth.uid(), organization_id, 'ceo'));

-- RLS Policies for profiles
CREATE POLICY "Users can view all profiles"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update their own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- RLS Policies for departments
CREATE POLICY "Users can view departments in their organization"
  ON public.departments FOR SELECT
  USING (public.belongs_to_org(auth.uid(), organization_id));

CREATE POLICY "CEOs and engine heads can create departments"
  ON public.departments FOR INSERT
  WITH CHECK (
    public.has_role(auth.uid(), organization_id, 'ceo') OR
    auth.uid() = engine_head_id
  );

CREATE POLICY "CEOs and engine heads can update departments"
  ON public.departments FOR UPDATE
  USING (
    public.has_role(auth.uid(), organization_id, 'ceo') OR
    auth.uid() = engine_head_id
  );

-- RLS Policies for scorecards
CREATE POLICY "Users can view scorecards in their organization"
  ON public.scorecards FOR SELECT
  USING (public.belongs_to_org(auth.uid(), organization_id));

CREATE POLICY "CEOs and owners can create scorecards"
  ON public.scorecards FOR INSERT
  WITH CHECK (
    public.has_role(auth.uid(), organization_id, 'ceo') OR
    auth.uid() = owner_id
  );

CREATE POLICY "CEOs and owners can update scorecards"
  ON public.scorecards FOR UPDATE
  USING (
    public.has_role(auth.uid(), organization_id, 'ceo') OR
    auth.uid() = owner_id
  );

-- RLS Policies for metrics
CREATE POLICY "Users can view metrics in their organization"
  ON public.metrics FOR SELECT
  USING (public.belongs_to_org(auth.uid(), organization_id));

CREATE POLICY "CEOs and metric owners can create metrics"
  ON public.metrics FOR INSERT
  WITH CHECK (
    public.has_role(auth.uid(), organization_id, 'ceo') OR
    auth.uid() = owner_id
  );

CREATE POLICY "CEOs and metric owners can update metrics"
  ON public.metrics FOR UPDATE
  USING (
    public.has_role(auth.uid(), organization_id, 'ceo') OR
    auth.uid() = owner_id
  );

-- Trigger to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger for updated_at timestamps
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER set_organizations_updated_at
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_departments_updated_at
  BEFORE UPDATE ON public.departments
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_scorecards_updated_at
  BEFORE UPDATE ON public.scorecards
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_metrics_updated_at
  BEFORE UPDATE ON public.metrics
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();