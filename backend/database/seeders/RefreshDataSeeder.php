<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use App\Models\User;
use App\Models\Book;
use App\Models\Category;
use App\Models\BookParagraph;

class RefreshDataSeeder extends Seeder
{
    public function run()
    {
        DB::statement('SET FOREIGN_KEY_CHECKS=0;');

        // Delete non-admin users
        User::where('role', '!=', 'admin')->delete();

        // Truncate all book and user related tables
        DB::table('book_paragraphs')->truncate();
        DB::table('highlights')->truncate();
        DB::table('vocabularies')->truncate();
        DB::table('reading_progress')->truncate();
        DB::table('collection_books')->truncate();
        DB::table('collections')->truncate();
        DB::table('downloaded_books')->truncate();
        DB::table('backups')->truncate();
        DB::table('app_notifications')->truncate();
        DB::table('books')->truncate();

        DB::statement('SET FOREIGN_KEY_CHECKS=1;');

        // Get some valid categories
        $categories = Category::pluck('name')->toArray();
        if (empty($categories)) {
            $categories = ['General', 'Fiction', 'Non-Fiction']; 
        }

        $booksData = [
            [
                'title' => 'Pride and Prejudice',
                'author' => 'Jane Austen',
                'color' => '#6E3B4E',
                'time' => '15 min read',
                'content' => [
                    "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
                    "However little known the feelings or views of such a man may be on his first entering a neighbourhood, this truth is so well fixed in the minds of the surrounding families, that he is considered the rightful property of some one or other of their daughters.",
                    "\"My dear Mr. Bennet,\" said his lady to him one day, \"have you heard that Netherfield Park is let at last?\"",
                    "Mr. Bennet replied that he had not.",
                    "\"But it is,\" returned she; \"for Mrs. Long has just been here, and she told me all about it.\"",
                    "Mr. Bennet made no answer.",
                    "\"Do you not want to know who has taken it?\" cried his wife impatiently.",
                    "\"You want to tell me, and I have no objection to hearing it.\"",
                    "This was invitation enough.",
                    "\"Why, my dear, you must know, Mrs. Long says that Netherfield is taken by a young man of large fortune from the north of England.\""
                ]
            ],
            [
                'title' => 'The Great Gatsby',
                'author' => 'F. Scott Fitzgerald',
                'color' => '#2E4C6D',
                'time' => '12 min read',
                'content' => [
                    "In my younger and more vulnerable years my father gave me some advice that I've been turning over in my mind ever since.",
                    "\"Whenever you feel like criticizing any one,\" he told me, \"just remember that all the people in this world haven't had the advantages that you've had.\"",
                    "He didn't say any more, but we've always been unusually communicative in a reserved way, and I understood that he meant a great deal more than that.",
                    "In consequence, I'm inclined to reserve all judgments, a habit that has opened up many curious natures to me and also made me the victim of not a few veteran bores.",
                    "The abnormal mind is quick to detect and attach itself to this quality when it appears in a normal person, and so it came about that in college I was unjustly accused of being a politician, because I was privy to the secret griefs of wild, unknown men.",
                    "Most of the confidences were unsought—frequently I have feigned sleep, preoccupation, or a hostile levity when I realized by some unmistakable sign that an intimate revelation was quivering on the horizon.",
                    "Reserving judgments is a matter of infinite hope. I am still a little afraid of missing something if I forget that, as my father snobbishly suggested, and I snobbishly repeat, a sense of the fundamental decencies is parcelled out unequally at birth.",
                    "And, after boasting this way of my tolerance, I come to the admission that it has a limit.",
                    "Conduct may be founded on the hard rock or the wet marshes, but after a certain point I don't care what it's founded on.",
                    "When I came back from the East last autumn I felt that I wanted the world to be in uniform and at a sort of moral attention forever."
                ]
            ],
            [
                'title' => 'Moby-Dick',
                'author' => 'Herman Melville',
                'color' => '#8B5A2B',
                'time' => '20 min read',
                'content' => [
                    "Call me Ishmael. Some years ago—never mind how long precisely—having little or no money in my purse, and nothing particular to interest me on shore, I thought I would sail about a little and see the watery part of the world.",
                    "It is a way I have of driving off the spleen and regulating the circulation.",
                    "Whenever I find myself growing grim about the mouth; whenever it is a damp, drizzly November in my soul; whenever I find myself involuntarily pausing before coffin warehouses, and bringing up the rear of every funeral I meet;",
                    "and especially whenever my hypos get such an upper hand of me, that it requires a strong moral principle to prevent me from deliberately stepping into the street, and methodically knocking people's hats off—then, I account it high time to get to sea as soon as I can.",
                    "This is my substitute for pistol and ball. With a philosophical flourish Cato throws himself upon his sword; I quietly take to the ship.",
                    "There is nothing surprising in this. If they but knew it, almost all men in their degree, some time or other, cherish very nearly the same feelings towards the ocean with me.",
                    "There now is your insular city of the Manhattoes, belted round by wharves as Indian isles by coral reefs—commerce surrounds it with her surf.",
                    "Right and left, the streets take you waterward. Its extreme downtown is the battery, where that noble mole is washed by waves, and cooled by breezes, which a few hours previous were out of sight of land.",
                    "Look at the crowds of water-gazers there.",
                    "Circumambulate the city of a dreamy Sabbath afternoon. Go from Corlears Hook to Coenties Slip, and from thence, by Whitehall, northward. What do you see?"
                ]
            ],
            [
                'title' => 'Frankenstein',
                'author' => 'Mary Shelley',
                'color' => '#16241D',
                'time' => '14 min read',
                'content' => [
                    "I am by birth a Genevese, and my family is one of the most distinguished of that republic.",
                    "My ancestors had been for many years counsellors and syndics, and my father had filled several public situations with honour and reputation.",
                    "He was respected by all who knew him for his integrity and indefatigable attention to public business.",
                    "He passed his younger days perpetually occupied by the affairs of his country; a variety of circumstances had prevented his marrying early, nor was it until the decline of life that he became a husband and the father of a family.",
                    "As the circumstances of his marriage illustrate his character, I cannot refrain from relating them.",
                    "One of his most intimate friends was a merchant who, from a flourishing state, fell, through numerous mischances, into poverty.",
                    "This man, whose name was Beaufort, was of a proud and unbending disposition and could not bear to live in poverty and oblivion in the same country where he had formerly been distinguished for his rank and magnificence.",
                    "Having paid his debts, therefore, in the most honourable manner, he retreated with his daughter to the town of Lucerne, where he lived unknown and in wretchedness.",
                    "My father loved Beaufort with the truest friendship and was deeply grieved by his retreat in these unfortunate circumstances.",
                    "He bitterly deplored the false pride which led his friend to a conduct so little worthy of the affection that united them."
                ]
            ],
            [
                'title' => 'Alice in Wonderland',
                'author' => 'Lewis Carroll',
                'color' => '#4B6B4A',
                'time' => '10 min read',
                'content' => [
                    "Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, 'and what is the use of a book,' thought Alice 'without pictures or conversations?'",
                    "So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her.",
                    "There was nothing so very remarkable in that; nor did Alice think it so very much out of the way to hear the Rabbit say to itself, 'Oh dear! Oh dear! I shall be late!' (when she thought it over afterwards, it occurred to her that she ought to have wondered at this, but at the time it all seemed quite natural);",
                    "but when the Rabbit actually took a watch out of its waistcoat-pocket, and looked at it, and then hurried on, Alice started to her feet, for it flashed across her mind that she had never before seen a rabbit with either a waistcoat-pocket, or a watch to take out of it,",
                    "and burning with curiosity, she ran across the field after it, and fortunately was just in time to see it pop down a large rabbit-hole under the hedge.",
                    "In another moment down went Alice after it, never once considering how in the world she was to get out again.",
                    "The rabbit-hole went straight on like a tunnel for some way, and then dipped suddenly down, so suddenly that Alice had not a moment to think about stopping herself before she found herself falling down a very deep well.",
                    "Either the well was very deep, or she fell very slowly, for she had plenty of time as she went down to look about her and to wonder what was going to happen next.",
                    "First, she tried to look down and make out what she was coming to, but it was too dark to see anything; then she looked at the sides of the well, and noticed that they were filled with cupboards and book-shelves; here and there she saw maps and pictures hung upon pegs.",
                    "She took down a jar from one of the shelves as she passed; it was labelled 'ORANGE MARMALADE', but to her great disappointment it was empty."
                ]
            ],
            [
                'title' => 'The Art of War',
                'author' => 'Sun Tzu',
                'color' => '#6E3B4E',
                'time' => '8 min read',
                'content' => [
                    "Sun Tzu said: The art of war is of vital importance to the State.",
                    "It is a matter of life and death, a road either to safety or to ruin. Hence it is a subject of inquiry which can on no account be neglected.",
                    "The art of war, then, is governed by five constant factors, to be taken into account in one's deliberations, when seeking to determine the conditions obtaining in the field.",
                    "These are: (1) The Moral Law; (2) Heaven; (3) Earth; (4) The Commander; (5) Method and discipline.",
                    "The Moral Law causes the people to be in complete accord with their ruler, so that they will follow him regardless of their lives, undismayed by any danger.",
                    "Heaven signifies night and day, cold and heat, times and seasons.",
                    "Earth comprises distances, great and small; danger and security; open ground and narrow passes; the chances of life and death.",
                    "The Commander stands for the virtues of wisdom, sincerely, benevolence, courage and strictness.",
                    "By method and discipline are to be understood the marshaling of the army in its proper subdivisions, the graduations of rank among the officers, the maintenance of roads by which supplies may reach the army, and the control of military expenditure.",
                    "These five heads should be familiar to every general: he who knows them will be victorious; he who knows them not will fail."
                ]
            ],
            [
                'title' => 'A Tale of Two Cities',
                'author' => 'Charles Dickens',
                'color' => '#2E4C6D',
                'time' => '16 min read',
                'content' => [
                    "It was the best of times, it was the worst of times,",
                    "it was the age of wisdom, it was the age of foolishness,",
                    "it was the epoch of belief, it was the epoch of incredulity,",
                    "it was the season of Light, it was the season of Darkness,",
                    "it was the spring of hope, it was the winter of despair,",
                    "we had everything before us, we had nothing before us,",
                    "we were all going direct to Heaven, we were all going direct the other way—",
                    "in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.",
                    "There were a king with a large jaw and a queen with a plain face, on the throne of England; there were a king with a large jaw and a queen with a fair face, on the throne of France.",
                    "In both countries it was clearer than crystal to the lords of the State preserves of loaves and fishes, that things in general were settled for ever."
                ]
            ],
            [
                'title' => 'Dracula',
                'author' => 'Bram Stoker',
                'color' => '#16241D',
                'time' => '18 min read',
                'content' => [
                    "Left Munich at 8:35 P.M., on 1st May, arriving at Vienna early next morning; should have arrived at 6:46, but train was an hour late.",
                    "Buda-Pesth seems a wonderful place, from the glimpse which I got of it from the train and the little I could walk through the streets.",
                    "I feared to go very far from the station, as we had arrived late and would start as near the correct time as possible.",
                    "The impression I had was that we were leaving the West and entering the East; the most western of splendid bridges over the Danube, which is here of noble width and depth, took us among the traditions of Turkish rule.",
                    "We left in pretty good time, and came after nightfall to Klausenburgh. Here I stopped for the night at the Hotel Royale.",
                    "I had for dinner, or rather supper, a chicken done up some way with red pepper, which was very good but thirsty. (Mem., get recipe for Mina.)",
                    "I asked the waiter, and he said it was called \"paprika hendl,\" and that, as it was a national dish, I should be able to get it anywhere along the Carpathians.",
                    "I found my smattering of German very useful here; indeed, I don't know how I should be able to get on without it.",
                    "Having had some time at my disposal when in London, I had visited the British Museum, and made search among the books and maps in the library regarding Transylvania; it had struck me that some foreknowledge of the country could hardly fail to have some importance in dealing with a nobleman of that country.",
                    "I find that the district he named is in the extreme east of the country, just on the borders of three states, Transylvania, Moldavia and Bukovina, in the midst of the Carpathian mountains; one of the wildest and least known portions of Europe."
                ]
            ],
            [
                'title' => 'The Metamorphosis',
                'author' => 'Franz Kafka',
                'color' => '#8B5A2B',
                'time' => '11 min read',
                'content' => [
                    "One morning, when Gregor Samsa woke from troubled dreams, he found himself transformed in his bed into a horrible vermin.",
                    "He lay on his armour-like back, and if he lifted his head a little he could see his brown belly, slightly domed and divided by arches into stiff sections.",
                    "The bedding was hardly able to cover it and seemed ready to slide off any moment.",
                    "His many legs, pitifully thin compared with the size of the rest of him, waved about helplessly as he looked.",
                    "\"What's happened to me?\" he thought. It wasn't a dream.",
                    "His room, a proper human room although a little too small, lay peacefully between its four familiar walls.",
                    "A collection of textile samples lay spread out on the table - Samsa was a travelling salesman - and above it there hung a picture that he had recently cut out of an illustrated magazine and housed in a nice, gilded frame.",
                    "It showed a lady fitted out with a fur hat and fur boa who sat upright, raising a heavy fur muff that covered the whole of her lower arm towards the viewer.",
                    "Gregor then turned to look out the window at the dull weather.",
                    "Drops of rain could be heard hitting the pane, which made him feel quite sad. \"How about if I sleep a little bit longer and forget all this nonsense\", he thought, but that was something he was unable to do because he was used to sleeping on his right, and in his present state couldn't get into that position."
                ]
            ],
            [
                'title' => 'Walden',
                'author' => 'Henry David Thoreau',
                'color' => '#4B6B4A',
                'time' => '22 min read',
                'content' => [
                    "When I wrote the following pages, or rather the bulk of them, I lived alone, in the woods, a mile from any neighbor, in a house which I had built myself, on the shore of Walden Pond, in Concord, Massachusetts, and earned my living by the labor of my hands only.",
                    "I lived there two years and two months. At present I am a sojourner in civilized life again.",
                    "I should not obtrude my affairs so much on the notice of my readers if very particular inquiries had not been made by my townsmen concerning my mode of life, which some would call impertinent, though they do not appear to me at all impertinent, but, considering the circumstances, very natural and pertinent.",
                    "Some have asked what I got to eat; if I did not feel lonesome; if I was not afraid; and the like.",
                    "Others have been curious to learn what portion of my income I devoted to charitable purposes; and some, who have large families, how many poor children I maintained.",
                    "I will therefore ask those of my readers who feel no particular interest in me to pardon me if I undertake to answer some of these questions in this book.",
                    "In most books, the I, or first person, is omitted; in this it will be retained; that, in respect to egotism, is the main difference.",
                    "We commonly do not remember that it is, after all, always the first person that is speaking.",
                    "I should not talk so much about myself if there were anybody else whom I knew as well.",
                    "Unfortunately, I am confined to this theme by the narrowness of my experience."
                ]
            ]
        ];

        foreach ($booksData as $b) {
            $catId = $categories[array_rand($categories)];

            $book = Book::create([
                'title' => $b['title'],
                'author' => $b['author'],
                'category' => $catId,
                'cover_color' => $b['color'],
                'read_time' => $b['time'],
                'source_type' => 'text',
                'is_public' => true,
                'is_featured' => rand(0, 1) == 1,
            ]);

            $index = 0;
            foreach ($b['content'] as $text) {
                BookParagraph::create([
                    'book_id' => $book->id,
                    'paragraph_index' => $index++,
                    'content' => $text,
                ]);
            }
        }
    }
}
