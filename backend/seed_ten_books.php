<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Book;
use App\Models\BookParagraph;
use App\Models\Category;

$booksData = [
    [
        'title' => 'The Psychology of Money',
        'author' => 'Morgan Housel',
        'category' => 'Business',
        'cover_color' => 'gold',
        'read_time' => '8 min read',
        'source_type' => 'article',
        'is_public' => true,
        'paragraphs' => [
            "Doing well with money has a little to do with how smart you are and a lot to do with how you behave. And behavior is hard to teach, even to really smart people.",
            "A genius who loses control of their emotions can be a financial disaster. The opposite is also true. Ordinary folks with no financial education can be wealthy if they have a handful of behavioral skills that have nothing to do with formal intelligence.",
            "Financial success is not a hard science. It is a soft skill, where how you behave is more important than what you know. I call this soft skill the psychology of money.",
            "Spending money to show people how much money you have is the fastest way to have less money. True wealth is what you do not see: the cars not purchased, the watches not worn, the first-class upgrades declined.",
            "Controlling your time is the highest dividend money pays. The ability to do what you want, when you want, with who you want, for as long as you want, is priceless.",
        ],
    ],
    [
        'title' => 'Meditations & The Inner Citadel',
        'author' => 'Marcus Aurelius',
        'category' => 'Philosophy',
        'cover_color' => 'forest',
        'read_time' => '10 min read',
        'source_type' => 'book',
        'is_public' => true,
        'paragraphs' => [
            "When you arise in the morning, think of what a precious privilege it is to be alive — to breathe, to think, to enjoy, to love.",
            "You have power over your mind — not outside events. Realize this, and you will find immense inner strength.",
            "Very little is needed to make a happy life; it is all within yourself, in your way of thinking.",
            "Waste no more time arguing about what a good person should be. Be one.",
            "The soul becomes dyed with the color of its thoughts. Dwell on the beauty of life. Watch the stars, and see yourself running with them.",
        ],
    ],
    [
        'title' => 'Deep Work: Rules for Focused Success',
        'author' => 'Cal Newport',
        'category' => 'Self-development',
        'cover_color' => 'navy',
        'read_time' => '12 min read',
        'source_type' => 'article',
        'is_public' => true,
        'paragraphs' => [
            "Deep Work is the ability to focus without distraction on a cognitively demanding task. It is a superpower in our increasingly competitive twenty-first-century economy.",
            "To produce at your peak level you need to work for extended periods with full concentration on a single task free from distraction. Put simply, the type of work that optimizes your performance is deep work.",
            "If you do not produce, you will not thrive. If you do not cultivate the ability to learn complex things quickly, you will be left behind.",
            "Clarity about what matters provides clarity about what does not. The key to developing a deep work habit is to move beyond good intentions and add routines and rituals to your working life.",
            "To simply wait for inspiration to strike is to resign yourself to a life of mediocre output.",
        ],
    ],
    [
        'title' => 'Sapiens: A Brief History of Humankind',
        'author' => 'Yuval Noah Harari',
        'category' => 'Education',
        'cover_color' => 'plum',
        'read_time' => '15 min read',
        'source_type' => 'book',
        'is_public' => true,
        'paragraphs' => [
            "Seventy thousand years ago, organisms belonging to the species Homo sapiens started to form even more elaborate structures called cultures.",
            "The Cognitive Revolution occurred between 70,000 to 30,000 years ago. It allowed Sapiens to communicate at a level of complexity never before seen on planet Earth.",
            "Any large-scale human cooperation — whether a modern state, a medieval church, an ancient city, or an archaic tribe — is rooted in common myths that exist only in people’s collective imagination.",
            "Two lawyers who have never met can nevertheless combine efforts to defend a complete stranger because both believe in the existence of laws, justice, human rights, and the money paid in their fees.",
            "We study history not to know the future, but to widen our horizons, to understand that our present situation is neither natural nor inevitable.",
        ],
    ],
    [
        'title' => 'Thinking, Fast and Slow',
        'author' => 'Daniel Kahneman',
        'category' => 'Research',
        'cover_color' => 'forest',
        'read_time' => '14 min read',
        'source_type' => 'book',
        'is_public' => true,
        'paragraphs' => [
            "The cognitive system of human beings is divided into two operational modes: System 1 operates automatically and quickly, with little or no effort. System 2 allocates attention to effortful mental operations.",
            "System 1 runs automatically and cannot be turned off at will; biases cannot always be avoided because System 2 may have no clue to the error.",
            "A reliable way to make people believe in falsehoods is frequent repetition, because familiarity is not easily distinguished from truth.",
            "Confidence is a feeling, which reflects the coherence of the information and the cognitive ease of processing it. It is wise to take admissions of uncertainty seriously.",
            "We can be blind to the obvious, and we are also blind to our blindness.",
        ],
    ],
    [
        'title' => 'The Courage to Be Disliked',
        'author' => 'Ichiro Kishimi',
        'category' => 'Philosophy',
        'cover_color' => 'gold',
        'read_time' => '9 min read',
        'source_type' => 'book',
        'is_public' => true,
        'paragraphs' => [
            "The courage to be happy also includes the courage to be disliked. When you have gained that courage, your interpersonal relationships will all at once lift toward freedom.",
            "No experience is in itself a cause of our success or failure. We do not suffer from the shock of our experiences — the so-called trauma — but instead we make out of them whatever suits our purposes.",
            "All interpersonal relationship troubles are caused by intruding on other people's tasks, or having one's own tasks intruded on.",
            "Do not live to satisfy the expectations of others. And other people do not live to satisfy your expectations.",
            "Life in general has no meaning. Whatever meaning life has is what you assign to it through your own daily choices.",
        ],
    ],
    [
        'title' => 'The Architecture of Clean Code',
        'author' => 'Robert C. Martin',
        'category' => 'Education',
        'cover_color' => 'navy',
        'read_time' => '11 min read',
        'source_type' => 'article',
        'is_public' => true,
        'paragraphs' => [
            "Clean code is simple and direct. Clean code reads like well-written prose. Clean code never obscures the designer's intent but rather is full of crisp abstractions and straightforward lines of control.",
            "The only valid measurement of code quality is WTFs per minute during code reviews.",
            "You should name a variable using the same care with which you name a first-born child.",
            "Functions should do one thing. They should do it well. They should do it only.",
            "Leave the campground cleaner than you found it. If we all check in our code a little cleaner than when we checked it out, the code simply cannot rot.",
        ],
    ],
    [
        'title' => 'The Midnight Library',
        'author' => 'Matt Haig',
        'category' => 'Fiction',
        'cover_color' => 'plum',
        'read_time' => '7 min read',
        'source_type' => 'book',
        'is_public' => true,
        'paragraphs' => [
            "Between life and death there is a library, and within that library, the shelves go on forever. Every book provides a chance to try another life you could have lived.",
            "To see how things would be if you had made other choices... Would you have done anything different, if you had the chance to undo your regrets?",
            "It is easy to mourn the lives we aren't living. It is easy to wish we'd developed other talents, said yes to different offers. It is easy to wish we'd worked harder, loved better, handled our money more cleverly.",
            "You don't have to understand life. You just have to live it.",
            "Never underestimate the big importance of small things.",
        ],
    ],
    [
        'title' => 'Zero to One: Building The Future',
        'author' => 'Peter Thiel',
        'category' => 'Business',
        'cover_color' => 'forest',
        'read_time' => '13 min read',
        'source_type' => 'book',
        'is_public' => true,
        'paragraphs' => [
            "Every moment in business happens only once. The next Bill Gates will not build an operating system. The next Larry Page or Sergey Brin won't make a search engine.",
            "If you are copying these people, you aren't learning from them. Going from 0 to 1 means creating something entirely new.",
            "The most contrarian thing of all is not to oppose the crowd but to think for yourself.",
            "All failed companies are the same: they failed to escape competition. Monopolies drive progress because the promise of years or decades of monopoly profits provides a powerful incentive to innovate.",
            "Proprietary technology is the most substantive advantage a company can have because it makes your product difficult or impossible to replicate.",
        ],
    ],
    [
        'title' => 'Atomic Habits & Micro Mastery',
        'author' => 'James Clear',
        'category' => 'Self-development',
        'cover_color' => 'gold',
        'read_time' => '10 min read',
        'source_type' => 'book',
        'is_public' => true,
        'paragraphs' => [
            "You do not rise to the level of your goals. You fall to the level of your systems. Your goal is your desired outcome; your system is the collection of daily habits that will get you there.",
            "Habits are the compound interest of self-improvement. The effects of your habits multiply as you repeat them over months and years.",
            "If you want better results, then forget about setting goals. Focus on your system instead.",
            "Every action you take is a vote for the type of person you wish to become. No single instance will transform your beliefs, but as the votes build up, so does the evidence of your new identity.",
            "Small changes make a big difference when compounded over time.",
        ],
    ],
];

echo "Seeding 10 Admin Catalog Books into Database...\n";

foreach ($booksData as $index => $bData) {
    $paragraphs = $bData['paragraphs'];
    unset($bData['paragraphs']);

    $book = Book::updateOrCreate(
        ['title' => $bData['title']],
        $bData
    );

    // Remove existing paragraphs to avoid duplicates, then insert fresh
    BookParagraph::where('book_id', $book->id)->delete();

    foreach ($paragraphs as $pIdx => $content) {
        BookParagraph::create([
            'book_id' => $book->id,
            'paragraph_index' => $pIdx,
            'content' => $content,
        ]);
    }

    echo "✓ [{$book->category}] {$book->title} by {$book->author} (" . count($paragraphs) . " paragraphs)\n";
}

echo "\n>>> 10 ADMIN BOOKS SUCCESSFULLY SEEDED INTO DATABASE! <<<\n";
