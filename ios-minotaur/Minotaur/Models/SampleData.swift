import Foundation

/// Seed content for the MVP. Everything the user creates is layered on top of this.
nonisolated enum SampleData {
    static let user = UserProfile(
        name: "Alex Rivers",
        handle: "@alexrivers",
        tagline: "Proven by results, not followers.",
        avatar: .asset("strength_coach_portrait"),
        verified: true
    )

    static func block(_ name: String, _ target: String, _ sets: Int, _ reps: String, _ rest: Int, _ note: String? = nil) -> ExerciseBlock {
        ExerciseBlock(name: name, target: target, sets: sets, reps: reps, restSeconds: rest, note: note)
    }

    static let nightwingDays: [ProgramDay] = [
        ProgramDay(number: 1, weekday: "Monday", title: "Upper Body Heavy",
                   notes: "Open with intent. Every working set is a statement. Leave two reps in reserve on the first block.",
                   estimatedMinutes: 62,
                   blocks: [
                    block("Barbell Bench Press", "Chest", 4, "4-6", 180, "Three second negative."),
                    block("Incline Dumbbell Press", "Upper Chest", 3, "8-10", 90),
                    block("Weighted Pull-Up", "Lats", 4, "6-8", 120)
                   ]),
        ProgramDay(number: 2, weekday: "Tuesday", title: "Lower Anterior",
                   notes: "Knees track over toes. Control the descent, explode out of the hole.",
                   estimatedMinutes: 58,
                   blocks: [
                    block("Back Squat", "Quads", 5, "5", 180),
                    block("Bulgarian Split Squat", "Glutes", 3, "10", 90),
                    block("Leg Extension", "Quads", 3, "15", 60)
                   ]),
        ProgramDay(number: 3, weekday: "Monday", title: "Arm Day",
                   notes: "Focus strictly on eccentric control for all bicep movements. Do not use momentum. Keep rest at 45 seconds between working sets to maximize metabolic stress. If form breaks down, drop weight by 10%.",
                   estimatedMinutes: 60,
                   blocks: [
                    block("Close-Grip Bench", "Triceps / Chest", 3, "12", 45, "Elbows tucked at 30 degrees."),
                    block("Cable Curls", "Biceps", 4, "15", 45),
                    block("Skullcrushers", "Triceps", 3, "10", 45),
                    block("Hammer Curl", "Brachialis", 3, "12", 45),
                    block("Rope Pushdown", "Triceps", 3, "20", 45),
                    block("Reverse Curl", "Forearms", 2, "15", 45)
                   ]),
        ProgramDay(number: 4, weekday: "Thursday", title: "Posterior Chain",
                   notes: "Hinge, do not squat. Brace hard before every rep.",
                   estimatedMinutes: 55,
                   blocks: [
                    block("Deficit Deadlift", "Hamstrings", 4, "3-5", 210),
                    block("Barbell Row", "Mid Back", 4, "8", 120),
                    block("Face Pull", "Rear Delts", 3, "20", 60)
                   ]),
        ProgramDay(number: 5, weekday: "Friday", title: "Shoulders & Core",
                   notes: "Strict pressing only. No leg drive unless specified.",
                   estimatedMinutes: 48,
                   blocks: [
                    block("Overhead Press", "Delts", 5, "5", 150),
                    block("Lateral Raise", "Side Delts", 4, "15", 45),
                    block("Hanging Leg Raise", "Core", 3, "12", 60)
                   ]),
        ProgramDay(number: 6, weekday: "Saturday", title: "Active Recovery",
                   notes: "Move, breathe, do not train. Thirty minutes of low intensity work.",
                   estimatedMinutes: 30,
                   blocks: []),
        ProgramDay(number: 7, weekday: "Monday", title: "Upper Body Volume",
                   notes: "Higher reps, shorter rest. Chase the pump, not the number.",
                   estimatedMinutes: 57,
                   blocks: [
                    block("Machine Chest Press", "Chest", 4, "12", 60),
                    block("Chest Supported Row", "Back", 4, "12", 60),
                    block("Cable Fly", "Chest", 3, "15", 45)
                   ]),
        ProgramDay(number: 8, weekday: "Tuesday", title: "Lower Volume",
                   notes: "Tempo work. Four seconds down on every rep of block A.",
                   estimatedMinutes: 54,
                   blocks: [
                    block("Front Squat", "Quads", 4, "8", 120),
                    block("Romanian Deadlift", "Hamstrings", 4, "10", 90),
                    block("Calf Raise", "Calves", 4, "20", 45)
                   ]),
        ProgramDay(number: 9, weekday: "Wednesday", title: "Arm Density",
                   notes: "Superset every pair. Ninety seconds between rounds.",
                   estimatedMinutes: 44,
                   blocks: [
                    block("EZ Bar Curl", "Biceps", 4, "10", 60),
                    block("Dips", "Triceps", 4, "10", 60),
                    block("Preacher Curl", "Biceps", 3, "12", 45)
                   ]),
        ProgramDay(number: 10, weekday: "Thursday", title: "Pull Intensity",
                   notes: "Every set to technical failure. Log your numbers.",
                   estimatedMinutes: 59,
                   blocks: [
                    block("Weighted Chin-Up", "Lats", 5, "5", 150),
                    block("Single Arm Row", "Lats", 4, "10", 75),
                    block("Shrug", "Traps", 3, "15", 60)
                   ]),
        ProgramDay(number: 11, weekday: "Friday", title: "Push Intensity",
                   notes: "Final heavy session of the block. Warm up thoroughly.",
                   estimatedMinutes: 61,
                   blocks: [
                    block("Bench Press", "Chest", 5, "3", 210),
                    block("Push Press", "Delts", 4, "5", 150),
                    block("Tricep Extension", "Triceps", 3, "12", 60)
                   ]),
        ProgramDay(number: 12, weekday: "Saturday", title: "The Exit",
                   notes: "The last corridor. Empty the tank, then log your final photo.",
                   estimatedMinutes: 65,
                   blocks: [
                    block("Deadlift", "Full Body", 3, "1-3", 240),
                    block("Weighted Pull-Up", "Lats", 3, "5", 120),
                    block("Farmer Carry", "Grip / Core", 4, "40m", 90)
                   ])
    ]

    static func genericDays(_ count: Int, focus: [String]) -> [ProgramDay] {
        let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return (0..<count).map { index in
            ProgramDay(
                number: index + 1,
                weekday: weekdays[index % weekdays.count],
                title: focus[index % focus.count],
                notes: "Execute the prescribed load with strict form. Log every set before you leave the floor.",
                estimatedMinutes: 50 + (index % 3) * 6,
                blocks: [
                    block("Primary Lift", "Compound", 4, "6-8", 150),
                    block("Secondary Lift", "Accessory", 3, "10", 90),
                    block("Finisher", "Isolation", 3, "15", 60)
                ]
            )
        }
    }

    static let nightwing = Labyrinth(
        id: UUID(uuidString: "B1000000-0000-0000-0000-000000000001")!,
        name: "Nightwing Routine",
        ownerName: "Dane Cole",
        ownerHandle: "@nightwing",
        ownerAvatar: .asset("strength_coach_portrait"),
        tagline: "A focused strength and muscle-building plan for experienced lifters.",
        cover: .asset("hands_gripping_dumbbell"),
        weeks: 12,
        daysPerWeek: 4,
        level: "Advanced",
        category: "Hypertrophy",
        price: nil,
        memberCount: 4_820,
        official: false,
        isPublic: true,
        dmEnabled: true,
        days: nightwingDays
    )

    static let titan = Labyrinth(
        id: UUID(uuidString: "B1000000-0000-0000-0000-000000000002")!,
        name: "Titan Strength",
        ownerName: "Minotaur Labs",
        ownerHandle: "@minotaurlabs",
        ownerAvatar: nil,
        tagline: "Build strength steadily with a clear, progressive lifting plan.",
        cover: .asset("athlete_deadlift_barbell"),
        weeks: 16,
        daysPerWeek: 4,
        level: "Advanced",
        category: "Strength",
        price: nil,
        memberCount: 12_400,
        official: true,
        isPublic: true,
        dmEnabled: false,
        days: genericDays(8, focus: ["Squat Primary", "Bench Primary", "Deadlift Primary", "Press Primary"])
    )

    static let gravity = Labyrinth(
        id: UUID(uuidString: "B1000000-0000-0000-0000-000000000003")!,
        name: "Gravity Breaker",
        ownerName: "Gaia",
        ownerHandle: "@gaia",
        ownerAvatar: nil,
        tagline: "Bodyweight mastery. No iron, no excuses, no equipment.",
        cover: .asset("man_pullup_back"),
        weeks: 10,
        daysPerWeek: 5,
        level: "Intermediate",
        category: "Calisthenics",
        price: 20,
        memberCount: 3_110,
        official: false,
        isPublic: true,
        dmEnabled: true,
        days: genericDays(6, focus: ["Pull Skills", "Push Skills", "Core Lever", "Legs & Jumps"])
    )

    static let olympian = Labyrinth(
        id: UUID(uuidString: "B1000000-0000-0000-0000-000000000004")!,
        name: "The Olympian",
        ownerName: "Zeus",
        ownerHandle: "@zeus",
        ownerAvatar: nil,
        tagline: "Conditioning built for athletes who compete on wet concrete.",
        cover: .asset("athlete_sprinting_underpass"),
        weeks: 12,
        daysPerWeek: 5,
        level: "Elite",
        category: "Conditioning",
        price: 19.99,
        memberCount: 5_400,
        official: false,
        isPublic: true,
        dmEnabled: true,
        days: genericDays(6, focus: ["Sprint Blocks", "Plyo Ladder", "Tempo Runs", "Recovery Flow"])
    )

    static let basement = Labyrinth(
        id: UUID(uuidString: "B1000000-0000-0000-0000-000000000005")!,
        name: "Basement Built",
        ownerName: "Garage Lifter",
        ownerHandle: "@garagelifter",
        ownerAvatar: nil,
        tagline: "One rack, one bar, eight weeks. Built in the dark.",
        cover: .asset("basement_gym_squat_rack"),
        weeks: 8,
        daysPerWeek: 3,
        level: "Intermediate",
        category: "Strength",
        price: nil,
        memberCount: 230,
        official: false,
        isPublic: true,
        dmEnabled: false,
        days: genericDays(6, focus: ["Heavy Push", "Heavy Pull", "Legs"])
    )

    static let hyperDensity = Labyrinth(
        id: UUID(uuidString: "B1000000-0000-0000-0000-000000000006")!,
        name: "Hyper-Density Phase",
        ownerName: user.name,
        ownerHandle: user.handle,
        ownerAvatar: user.avatar,
        tagline: "Advanced architectural hypertrophy for seasoned lifters. Minimum three years training required.",
        cover: .asset("athlete_deadlift_barbell"),
        weeks: 12,
        daysPerWeek: 4,
        level: "Elite",
        category: "Hypertrophy",
        price: 49,
        memberCount: 812,
        official: false,
        isPublic: true,
        dmEnabled: true,
        days: genericDays(8, focus: ["Chest Density", "Back Density", "Leg Density", "Arm Density"])
    )

    static let thread = Labyrinth(
        id: UUID(uuidString: "B1000000-0000-0000-0000-000000000007")!,
        name: "The Thread: Entry",
        ownerName: user.name,
        ownerHandle: user.handle,
        ownerAvatar: user.avatar,
        tagline: "The introductory path into the Labyrinth system. Core mechanics and discipline fundamentals.",
        cover: .asset("basement_gym_squat_rack"),
        weeks: 2,
        daysPerWeek: 3,
        level: "Open",
        category: "Foundations",
        price: nil,
        memberCount: 2_040,
        official: false,
        isPublic: true,
        dmEnabled: false,
        days: genericDays(6, focus: ["Full Body A", "Full Body B", "Full Body C"])
    )

    /// Clearly marked demonstration content, not a coach-reviewed production prescription.
    static let foundations = Labyrinth(
        id: UUID(uuidString: "B1000000-0000-0000-0000-000000000008")!,
        name: "Full body foundations", ownerName: "Minotaur", ownerHandle: "@minotaur",
        ownerAvatar: nil, tagline: "A friendly place to start. Simple movements, space to learn, and a rhythm you can make your own.",
        cover: .asset("foundations_color"), weeks: 0, daysPerWeek: 3, level: "Beginner",
        category: "Strength", price: nil, memberCount: 0, official: false, isPublic: true, dmEnabled: false,
        days: [
            ProgramDay(number: 1, weekday: "Day 1", title: "Your first full body session",
                notes: "Demo workout. Start with a comfortable load and range of motion. Rest as needed.", estimatedMinutes: 25,
                blocks: [
                    ExerciseBlock(name: "Goblet squat", target: "Legs", sets: 2, reps: "8–10", restSeconds: 60, note: "Choose a load you can control comfortably."),
                    ExerciseBlock(name: "Incline push-up", target: "Chest", sets: 2, reps: "8–10", restSeconds: 60, note: "Use a stable raised surface."),
                    ExerciseBlock(name: "Dumbbell row", target: "Back", sets: 2, reps: "8 each side", restSeconds: 60, note: "Move slowly and stay supported.")
                ]),
            ProgramDay(number: 2, weekday: "Day 2", title: "Build your base",
                notes: "Demo workout. Take a rest day between sessions if you need one.", estimatedMinutes: 25,
                blocks: [
                    ExerciseBlock(name: "Low step-up", target: "Legs", sets: 2, reps: "8 each side", restSeconds: 60, note: "Use a low, stable step."),
                    ExerciseBlock(name: "Dumbbell floor press", target: "Chest", sets: 2, reps: "8–10", restSeconds: 60, note: nil),
                    ExerciseBlock(name: "Glute bridge", target: "Glutes", sets: 2, reps: "10", restSeconds: 60, note: nil)
                ]),
            ProgramDay(number: 3, weekday: "Day 3", title: "Find your flow",
                notes: "Demo workout. Repeat the sequence at a pace that works for you.", estimatedMinutes: 25,
                blocks: [
                    ExerciseBlock(name: "Bodyweight squat", target: "Legs", sets: 2, reps: "10", restSeconds: 60, note: nil),
                    ExerciseBlock(name: "Dumbbell row", target: "Back", sets: 2, reps: "8 each side", restSeconds: 60, note: nil),
                    ExerciseBlock(name: "Wall push-up", target: "Chest", sets: 2, reps: "10", restSeconds: 60, note: nil)
                ])
        ], format: .ongoing, goal: "Build muscle", equipment: "Gym"
    )

    static let labyrinths: [Labyrinth] = [foundations, nightwing, titan, gravity, olympian, basement, hyperDensity, thread]

    /// Stable IDs let these discovery examples be safely added to existing local installs once.
    static let featuredTransformationPosts: [Post] = [
        Post(id: UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!,
             labyrinthID: nightwing.id,
             authorName: "MARCUS_T",
             authorAvatar: nil,
             isFounder: false,
             createdAt: Date().addingTimeInterval(-10_800),
             text: "Day 84. The scale moved slowly, but the strength and consistency changed everything.",
             tag: .progress,
             photo: nil,
             pair: ProgressPair(baseline: .asset("man_fitness_before_photo"), current: .asset("muscular_man_progress_after"), daysIn: 84),
             likes: 1_284,
             likedByMe: false,
             commentCount: 96,
             shares: 143,
             pinned: false, discoveryConsent: true),
        Post(id: UUID(uuidString: "A1000000-0000-0000-0000-000000000002")!,
             labyrinthID: titan.id,
             authorName: "JULES.PR",
             authorAvatar: nil,
             isFounder: false,
             createdAt: Date().addingTimeInterval(-32_400),
             text: "Sixteen weeks under the bar. Stronger posture, stronger lifts, stronger habits.",
             tag: .progress,
             photo: nil,
             pair: ProgressPair(baseline: .asset("man_fitness_before_photo"), current: .asset("athlete_deadlift_barbell"), daysIn: 112),
             likes: 938,
             likedByMe: false,
             commentCount: 71,
             shares: 88,
             pinned: false, discoveryConsent: true),
        Post(id: UUID(uuidString: "A1000000-0000-0000-0000-000000000003")!,
             labyrinthID: gravity.id,
             authorName: "NOAH_MOVES",
             authorAvatar: nil,
             isFounder: false,
             createdAt: Date().addingTimeInterval(-64_800),
             text: "Started without a single pull-up. Finished the cycle owning sets of ten.",
             tag: .progress,
             photo: nil,
             pair: ProgressPair(baseline: .asset("man_fitness_before_photo"), current: .asset("man_pullup_back"), daysIn: 70),
             likes: 764,
             likedByMe: false,
             commentCount: 54,
             shares: 61,
             pinned: false, discoveryConsent: true)
    ]

    static func seedPosts() -> [Post] {
        featuredTransformationPosts + [
            Post(labyrinthID: nightwing.id,
                 authorName: "Dane [Founder]",
                 authorAvatar: .asset("strength_coach_portrait"),
                 isFounder: true,
                 createdAt: Date().addingTimeInterval(-7_200),
                 text: "Reminder: we are entering Block 3 next week. Form over weight. Deload properly this weekend if your CNS feels fried. Drop any form check videos below if you're struggling with the deficit deadlifts.",
                 tag: .update,
                 photo: nil,
                 pair: nil,
                 likes: 124,
                 likedByMe: false,
                 commentCount: 45,
                 pinned: true),
            Post(labyrinthID: nightwing.id,
                 authorName: "user_784",
                 authorAvatar: nil,
                 isFounder: false,
                 createdAt: Date().addingTimeInterval(-14_400),
                 text: "Trusting the process. Finally breaking through the plateau on bench.",
                 tag: .progress,
                 photo: nil,
                 pair: ProgressPair(baseline: .asset("man_fitness_before_photo"), current: .asset("muscular_man_progress_after"), daysIn: 42),
                 likes: 89,
                 likedByMe: false,
                 commentCount: 12,
                 pinned: false),
            Post(labyrinthID: nightwing.id,
                 authorName: "ironclad_m",
                 authorAvatar: nil,
                 isFounder: false,
                 createdAt: Date().addingTimeInterval(-28_800),
                 text: "Question for the founder — should I keep the 45 second rest on skullcrushers if my elbows are aching? Or swap to rope work for the block?",
                 tag: .question,
                 photo: nil,
                 pair: nil,
                 likes: 14,
                 likedByMe: false,
                 commentCount: 3,
                 pinned: false),
            Post(labyrinthID: hyperDensity.id,
                 authorName: "sil_v",
                 authorAvatar: nil,
                 isFounder: false,
                 createdAt: Date().addingTimeInterval(-40_000),
                 text: "Week 4 done. The density blocks are brutal but the arms are finally responding.",
                 tag: .update,
                 photo: .asset("man_pullup_back"),
                 pair: nil,
                 likes: 31,
                 likedByMe: false,
                 commentCount: 4,
                 pinned: false),
            Post(labyrinthID: hyperDensity.id,
                 authorName: "quiet_reps",
                 authorAvatar: nil,
                 isFounder: false,
                 createdAt: Date().addingTimeInterval(-90_000),
                 text: "Is the rest period between density clusters 60 or 90 seconds? The notes say both in different days.",
                 tag: .question,
                 photo: nil,
                 pair: nil,
                 likes: 6,
                 likedByMe: false,
                 commentCount: 1,
                 pinned: false)
        ]
    }

    static func seedMessages() -> [DirectMessage] {
        [
            DirectMessage(labyrinthID: nightwing.id,
                          text: "Welcome to the Nightwing Routine. This thread reaches me directly — use it for anything the community feed can't answer.",
                          fromMe: false,
                          sentAt: Date().addingTimeInterval(-172_800)),
            DirectMessage(labyrinthID: nightwing.id,
                          text: "Appreciate it. Starting Block 1 tomorrow.",
                          fromMe: true,
                          sentAt: Date().addingTimeInterval(-171_000))
        ]
    }
}
