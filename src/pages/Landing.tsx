import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { BarChart3, Target, Users, TrendingUp } from "lucide-react";
import { Link } from "react-router-dom";

const Landing = () => {
  return (
    <div className="min-h-screen bg-background">
      {/* Navigation */}
      <nav className="border-b">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <BarChart3 className="h-6 w-6 text-primary" />
            <span className="text-xl font-bold">ScaleMyOrg.ai</span>
          </div>
          <div className="flex gap-4">
            <Link to="/login">
              <Button variant="ghost">Login</Button>
            </Link>
            <Link to="/signup">
              <Button>Get Started</Button>
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-20 text-center">
        <h1 className="text-5xl font-bold mb-6">
          Visualize, Structure, and Manage Your Organization's Performance
        </h1>
        <p className="text-xl text-muted-foreground mb-8 max-w-2xl mx-auto">
          Transform your Growth, Fulfillment, and Support functions into measurable, accountable systems with cascading scorecards.
        </p>
        <Link to="/signup">
          <Button size="lg" className="rounded-2xl px-8 py-6 text-lg">
            Start Building Your Scorecard
          </Button>
        </Link>
      </section>

      {/* Features */}
      <section className="container mx-auto px-4 py-16">
        <div className="grid md:grid-cols-3 gap-8">
          <Card className="rounded-2xl">
            <CardHeader>
              <Target className="h-12 w-12 text-primary mb-4" />
              <CardTitle>Hierarchical Scorecards</CardTitle>
              <CardDescription>
                Align every role from CEO to Metric Owner around shared performance goals
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="rounded-2xl">
            <CardHeader>
              <TrendingUp className="h-12 w-12 text-primary mb-4" />
              <CardTitle>Real-Time Visibility</CardTitle>
              <CardDescription>
                Track metrics across Growth, Fulfillment, and Support functions with live updates
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="rounded-2xl">
            <CardHeader>
              <Users className="h-12 w-12 text-primary mb-4" />
              <CardTitle>Role-Based Access</CardTitle>
              <CardDescription>
                Empower Engine Heads and Metric Owners with clear ownership and accountability
              </CardDescription>
            </CardHeader>
          </Card>
        </div>
      </section>

      {/* How It Works */}
      <section className="container mx-auto px-4 py-16">
        <h2 className="text-3xl font-bold text-center mb-12">How It Works</h2>
        <div className="max-w-3xl mx-auto space-y-8">
          <Card className="rounded-2xl">
            <CardHeader>
              <CardTitle>1. Create Your Organization</CardTitle>
              <CardDescription>
                CEOs initialize their organization and invite Engine Heads and Metric Owners
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="rounded-2xl">
            <CardHeader>
              <CardTitle>2. Define Your Metrics</CardTitle>
              <CardDescription>
                Set Hero Metrics and assign them across Growth, Fulfillment, and Support functions
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="rounded-2xl">
            <CardHeader>
              <CardTitle>3. Activate Scorecards</CardTitle>
              <CardDescription>
                Engine Heads create departments and add Key Performance Metrics that cascade from CEO goals
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="rounded-2xl">
            <CardHeader>
              <CardTitle>4. Track Performance</CardTitle>
              <CardDescription>
                Monitor progress with role-based dashboards and drill-down visibility
              </CardDescription>
            </CardHeader>
          </Card>
        </div>
      </section>

      {/* CTA */}
      <section className="container mx-auto px-4 py-20 text-center">
        <h2 className="text-4xl font-bold mb-6">Ready to Scale Your Organization?</h2>
        <p className="text-xl text-muted-foreground mb-8">
          Start measuring what matters today
        </p>
        <Link to="/signup">
          <Button size="lg" className="rounded-2xl px-8 py-6 text-lg">
            Get Started Free
          </Button>
        </Link>
      </section>

      {/* Footer */}
      <footer className="border-t py-8">
        <div className="container mx-auto px-4 text-center text-muted-foreground">
          <p>&copy; 2025 ScaleMyOrg.ai. All rights reserved.</p>
        </div>
      </footer>
    </div>
  );
};

export default Landing;
