"use client"

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { ExternalLink, BookOpen, Clock } from "lucide-react"
import { cn } from "@/lib/utils"
import Link from "next/link"

interface DocumentationCardProps {
  title: string
  description: string
  category: string
  difficulty?: "beginner" | "intermediate" | "advanced"
  readTime?: string
  tags?: string[]
  href: string
  lastUpdated?: Date
  className?: string
}

export function DocumentationCard({
  title,
  description,
  category,
  difficulty = "beginner",
  readTime,
  tags = [],
  href,
  lastUpdated,
  className,
}: DocumentationCardProps) {
  const difficultyColors = {
    beginner: "bg-green-500/10 text-green-500 border-green-500/20",
    intermediate: "bg-yellow-500/10 text-yellow-500 border-yellow-500/20",
    advanced: "bg-red-500/10 text-red-500 border-red-500/20",
  }

  return (
    <Card className={cn("group relative hover:shadow-lg transition-all", className)}>
      <CardHeader>
        <div className="flex items-start justify-between gap-4">
          <div className="space-y-1 flex-1">
            <CardTitle className="group-hover:text-primary transition-colors">
              <Link href={href} className="flex items-center gap-2">
                <BookOpen className="h-5 w-5" />
                {title}
              </Link>
            </CardTitle>
            <CardDescription>{description}</CardDescription>
          </div>
          <Badge variant="outline" className={difficultyColors[difficulty]}>
            {difficulty}
          </Badge>
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* Metadata */}
        <div className="flex flex-wrap items-center gap-4 text-sm text-muted-foreground">
          <div className="flex items-center gap-1">
            <span className="font-medium">Category:</span>
            <span>{category}</span>
          </div>
          {readTime && (
            <div className="flex items-center gap-1">
              <Clock className="h-4 w-4" />
              <span>{readTime}</span>
            </div>
          )}
          {lastUpdated && (
            <div className="flex items-center gap-1">
              <span className="text-xs">
                Updated {lastUpdated.toLocaleDateString()}
              </span>
            </div>
          )}
        </div>

        {/* Tags */}
        {tags.length > 0 && (
          <div className="flex flex-wrap gap-2">
            {tags.map((tag) => (
              <Badge key={tag} variant="secondary" className="text-xs">
                {tag}
              </Badge>
            ))}
          </div>
        )}

        {/* Action Button */}
        <Button asChild className="w-full" variant="outline">
          <Link href={href}>
            Read Documentation
            <ExternalLink className="ml-2 h-4 w-4" />
          </Link>
        </Button>
      </CardContent>
    </Card>
  )
}

// Usage Example:
// <DocumentationCard
//   title="Docker Best Practices"
//   description="Learn production-ready Docker patterns and optimization techniques"
//   category="Infrastructure"
//   difficulty="intermediate"
//   readTime="15 min"
//   tags={["docker", "containers", "devops"]}
//   href="/docs/docker/best-practices"
//   lastUpdated={new Date("2025-11-01")}
// />
