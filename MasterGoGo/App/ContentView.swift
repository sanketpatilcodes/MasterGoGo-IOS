//
//  ContentView.swift
//  MasterGoGo
//
//  Created by Sanket Patil on 18/11/26.
//

import SwiftUI

struct ContentView: View {
    private let container: AppContainer

    init(container: AppContainer = AppContainer()) {
        self.container = container
    }

    var body: some View {
        TabView {
            NavigationStack {
                CatalogView(repository: container.repository)
            }
            .tabItem {
                Label("Tutorials", systemImage: "book.closed")
            }

            NavigationStack {
                InterviewView(repository: container.repository)
            }
            .tabItem {
                Label("Interviews", systemImage: "bubble.left.and.bubble.right")
            }
        }
        .tint(PremiumTheme.accent)
    }
}

private struct CatalogView: View {
    @StateObject private var model: CatalogViewModel
    private let repository: ContentRepository

    init(repository: ContentRepository) {
        self.repository = repository
        _model = StateObject(wrappedValue: CatalogViewModel(repository: repository))
    }

    var body: some View {
        Group {
            if model.isLoading && model.sections.isEmpty {
                ProgressView("Loading courses…")
            } else if let errorMessage = model.errorMessage, model.sections.isEmpty {
                ErrorStateView(message: errorMessage) { Task { await model.load() } }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        PremiumHero(
                            eyebrow: "LEARN WITH INTENT",
                            title: "Master your craft.",
                            subtitle: "Focused tutorials for the skills that move your career forward."
                        )

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Explore collections")
                                .font(.title3.weight(.bold))
                            ForEach(model.sections) { section in
                                NavigationLink {
                                    SectionView(repository: repository, section: section)
                                } label: {
                                    SectionCard(section: section)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
                .refreshable { await model.load() }
            }
        }
        .navigationTitle("Tutorials")
        .task { await model.load() }
    }
}

private struct SectionView: View {
    let repository: ContentRepository
    let fallback: ContentSection
    @StateObject private var model: SectionViewModel

    init(repository: ContentRepository, section: ContentSection) {
        self.repository = repository
        fallback = section
        _model = StateObject(wrappedValue: SectionViewModel(repository: repository, slug: section.slug))
    }

    private var displayedSection: ContentSection { model.section ?? fallback }

    var body: some View {
        Group {
            if model.isLoading && displayedSection.courses.isEmpty {
                ProgressView("Loading section…")
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(displayedSection.courses) { course in
                            NavigationLink {
                                CourseView(repository: repository, sectionSlug: displayedSection.slug, courseSlug: course.slug, fallback: course)
                            } label: {
                                CourseCard(course: course)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .refreshable { await model.load() }
            }
        }
        .navigationTitle(displayedSection.title)
        .task { await model.load() }
    }
}

private struct CourseView: View {
    @StateObject private var model: CourseViewModel
    private let repository: ContentRepository
    private let sectionSlug: String
    private let fallback: Course

    init(repository: ContentRepository, sectionSlug: String, courseSlug: String, fallback: Course) {
        self.repository = repository
        self.sectionSlug = sectionSlug
        self.fallback = fallback
        _model = StateObject(wrappedValue: CourseViewModel(repository: repository, sectionSlug: sectionSlug, courseSlug: courseSlug))
    }

    private var displayedCourse: Course { model.course ?? fallback }

    var body: some View {
        Group {
            if model.isLoading && model.course == nil {
                ProgressView("Loading course…")
            } else if let errorMessage = model.errorMessage, model.course == nil {
                ErrorStateView(message: errorMessage) { Task { await model.load() } }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(displayedCourse.tutorials) { tutorial in
                            NavigationLink {
                                TutorialView(repository: repository, sectionSlug: sectionSlug, courseSlug: displayedCourse.slug, tutorialSlug: tutorial.slug, fallback: tutorial)
                            } label: {
                                TutorialCard(tutorial: tutorial, index: displayedCourse.tutorials.firstIndex(of: tutorial) ?? 0)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .refreshable { await model.load() }
            }
        }
        .navigationTitle(displayedCourse.title)
        .task { await model.load() }
    }
}

private struct TutorialView: View {
    @StateObject private var model: TutorialViewModel
    private let fallback: Tutorial

    init(repository: ContentRepository, sectionSlug: String, courseSlug: String, tutorialSlug: String, fallback: Tutorial) {
        self.fallback = fallback
        _model = StateObject(wrappedValue: TutorialViewModel(repository: repository, sectionSlug: sectionSlug, courseSlug: courseSlug, tutorialSlug: tutorialSlug))
    }

    private var displayedTutorial: Tutorial { model.tutorial ?? fallback }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let imageURL = model.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image.resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: .black.opacity(0.12), radius: 14, y: 8)
                        } else if phase.error == nil {
                            ProgressView().frame(maxWidth: .infinity, minHeight: 160)
                        }
                    }
                }
                Text("TUTORIAL")
                    .font(.caption.weight(.bold))
                    .tracking(1.3)
                    .foregroundStyle(PremiumTheme.accent)
                Text(displayedTutorial.title)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                if let summary = displayedTutorial.summary {
                    Text(summary).font(.headline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
                if let body = displayedTutorial.body {
                    Text(body)
                        .font(.body)
                        .lineSpacing(6)
                        .textSelection(.enabled)
                }
                if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else if let errorMessage = model.errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle(displayedTutorial.title)
        .task { await model.load() }
    }
}

private struct InterviewView: View {
    @StateObject private var model: InterviewViewModel

    init(repository: ContentRepository) {
        _model = StateObject(wrappedValue: InterviewViewModel(repository: repository))
    }

    var body: some View {
        Group {
            if model.isLoading && model.collection == nil {
                ProgressView("Loading interview questions…")
            } else if let errorMessage = model.errorMessage, model.collection == nil {
                ErrorStateView(message: errorMessage) { Task { await model.load() } }
            } else if let collection = model.collection {
                if collection.questions.isEmpty {
                    ContentUnavailableView(
                        "No interview questions",
                        systemImage: "text.book.closed",
                        description: Text("The server returned an empty interview collection.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            PremiumHero(
                                eyebrow: "INTERVIEW PREP",
                                title: "Think clearly. Answer confidently.",
                                subtitle: "Build your Android knowledge one thoughtful question at a time."
                            )
                            ForEach(collection.categories) { category in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(category.name)
                                        .font(.title3.weight(.bold))
                                    ForEach(category.questions) { question in
                                        InterviewQuestionCard(question: question)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable { await model.load() }
                }
            } else {
                ErrorStateView(message: "No interview data was received from the API.") {
                    Task { await model.load() }
                }
            }
        }
        .navigationTitle(model.collection?.appName ?? "Interviews")
        .task { await model.load() }
    }
}

private struct InterviewQuestionCard: View {
    let question: InterviewQuestion

    var body: some View {
        DisclosureGroup {
            Text(question.answer ?? "No answer available.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(PremiumTheme.accent)
                Text(question.question)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(16)
        .background(PremiumTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ErrorStateView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Unable to load content", systemImage: "wifi.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retry).buttonStyle(.borderedProminent)
        }
    }
}

private enum PremiumTheme {
    static let accent = Color(red: 0.30, green: 0.22, blue: 0.92)
    static let secondaryAccent = Color(red: 0.08, green: 0.72, blue: 0.76)
    static let cardBackground = Color.secondary.opacity(0.10)
}

private struct PremiumHero: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
            Text(eyebrow)
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.75))
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                colors: [PremiumTheme.accent, PremiumTheme.secondaryAccent],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: PremiumTheme.accent.opacity(0.25), radius: 18, y: 10)
    }
}

private struct CourseCard: View {
    let course: Course

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "graduationcap.fill")
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(PremiumTheme.accent.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title).font(.headline.weight(.bold))
                if let description = course.description {
                    Text(description).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
                Label("Course", systemImage: "play.circle")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PremiumTheme.accent)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(PremiumTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct TutorialCard: View {
    let tutorial: Tutorial
    let index: Int

    var body: some View {
        HStack(spacing: 14) {
            Text(String(format: "%02d", index + 1))
                .font(.title3.weight(.bold))
                .foregroundStyle(PremiumTheme.accent)
                .frame(width: 42)
            VStack(alignment: .leading, spacing: 5) {
                Text(tutorial.title).font(.headline.weight(.semibold))
                if let summary = tutorial.summary {
                    Text(summary).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: "arrow.right.circle.fill")
                .font(.title3)
                .foregroundStyle(PremiumTheme.accent)
        }
        .padding(16)
        .background(PremiumTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct SectionCard: View {
    let section: ContentSection

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: section.slug == "android" ? "cpu" : "chevron.left.forwardslash.chevron.right")
                .font(.title2.weight(.semibold))
                .foregroundStyle(PremiumTheme.accent)
                .frame(width: 50, height: 50)
                .background(PremiumTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text(section.title).font(.headline.weight(.bold))
                Text("\(section.courses.count) learning path\(section.courses.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.up.right")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(PremiumTheme.accent)
        }
        .padding(16)
        .background(PremiumTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

#Preview {
    ContentView()
}
