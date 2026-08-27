// Divine Worship: Daily Office (Ordinariate) — Little Hours, per prayer.covert.org
export const GLORIA = "Glory be to the Father, and to the Son, * and to the Holy Ghost.\nAs it was in the beginning, is now and ever shall be, * world without end. Amen.";

export const OFFICES = {
  terce: {
    key: "terce", latin: "Terce", name: "Midmorning Prayer", hour: "The Third Hour", defaultTime: "09:00",
    opening: [
      { v: "Officiant", t: "✠ O GOD, make speed to save us." },
      { v: "People", t: "O LORD, make haste to help us." }
    ],
    hymn: {
      latin: "Nunc Sancte nobis Spiritus",
      note: "Attributed to St. Ambrose. Hymnal 1940 #160, Translation by J. M. Neale.",
      verses: [
        "Come Holy Ghost, with God the Son,\nAnd God the Father, ever One;\nShed forth thy grace within our breast,\nand dwell with us, a ready guest.",
        "By ev'ry power, by heart and tongue,\nBy act and deed, thy praise be sung;\nInflame with perfect love each sense,\nThat others' souls may kindle thence.",
        "O Father, that we ask be done,\nthrough Jesus Christ, thine only Son,\nwho, with the Holy Ghost and thee,\ndoth live and reign eternally. Amen."
      ]
    },
    psalms: [
      { num: "Psalm 120", latin: "Ad Dominum", verses: [
        "WHEN I was in trouble, I called upon the Lord, * and he heard me.",
        "2 Deliver my soul, O Lord, from lying lips, * and from a deceitful tongue.",
        "3 What reward shall be given or done unto thee, thou false tongue? * even mighty and sharp arrows, with hot burning coals.",
        "4 Woe is me, that I am constrained to dwell with Meshech, * and to have my habitation among the tents of Kedar!",
        "5 My soul hath long dwelt among them * that are enemies unto peace.",
        "6 I labour for peace; but when I speak unto them thereof, * they make them ready to battle."
      ]},
      { num: "Psalm 121", latin: "Levavi oculos", verses: [
        "I WILL lift up mine eyes unto the hills; * from whence cometh my help?",
        "2 My help cometh even from the Lord, * who hath made heaven and earth.",
        "3 He will not suffer thy foot to be moved; * and he that keepeth thee will not sleep.",
        "4 Behold, he that keepeth Israel * shall neither slumber nor sleep.",
        "5 The Lord himself is thy keeper; * the Lord is thy defence upon thy right hand;",
        "6 So that the sun shall not burn thee by day, * neither the moon by night.",
        "7 The Lord shall preserve thee from all evil; * yea, it is even he that shall keep thy soul.",
        "8 The Lord shall preserve thy going out, and thy coming in, * from this time forth for evermore."
      ]},
      { num: "Psalm 122", latin: "Laetatus sum", verses: [
        "I WAS glad when they said unto me, * We will go into the house of the Lord.",
        "2 Our feet shall stand in thy gates, * O Jerusalem.",
        "3 Jerusalem is built as a city * that is at unity in itself.",
        "4 For thither the tribes go up, even the tribes of the Lord, * to testify unto Israel, to give thanks unto the Name of the Lord.",
        "5 For there is the seat of judgment, * even the seat of the house of David.",
        "6 O pray for the peace of Jerusalem; * they shall prosper that love thee.",
        "7 Peace be within thy walls, * and plenteousness within thy palaces.",
        "8 For my brethren and companions' sakes, * I will wish thee prosperity.",
        "9 Yea, because of the house of the Lord our God, * I will seek to do thee good."
      ]}
    ],
    chapters: { // index 0 = Sunday
      0: { ref: "1 John 4:16", text: "So we know and believe the love God has for us. God is love, and he who abides in love abides in God, and God abides in him.",
           versicle: "Incline my heart unto thy testimonies, O God;", response: "And quicken thou me in thy way." },
      1: { ref: "Romans 13:8, 10", text: "Owe no one anything, except to love one another; for he who loves his neighbour has fulfilled the law. Love does no wrong to a neighbour; therefore love is the fulfilling of the law.",
           versicle: "Thou hast been my succour; leave me not;", response: "Neither forsake me, O God of my salvation." },
      2: { ref: "Jeremiah 17:7-8", text: "Blessed is the man who trusts in the Lord, whose trust is the Lord. He is like a tree planted by water, that sends out its roots by the stream, and does not fear when heat comes, for its leaves remain green, and is not anxious in the year of drought, for it does not cease to bear fruit.",
           versicle: "The Lord God is a light and defence; the Lord will give grace and worship;", response: "O Lord God of hosts, blessed is the man that putteth his trust in thee." },
      3: { ref: "1 Peter 1:13-14", text: "Therefore gird up your minds, be sober, set your hope fully upon the grace that is coming to you at the revelation of Jesus Christ. As obedient children, do not be conformed to the passions of your former ignorance.",
           versicle: "Show me thy ways, O Lord;", response: "And teach me thy paths." },
      4: { ref: "Amos 4:13", text: "For behold, he who forms the mountains, and creates the wind, and declares to man what is his thought; who makes the morning darkness, and treads on the heights of the earth — the Lord, the God of hosts, is his Name!",
           versicle: "All ye works of the Lord, bless ye the Lord;", response: "Praise him, and magnify him for ever." },
      5: { ref: "Philippians 2:2b-4", text: "Be of the same mind, having the same love, being in full accord and of one mind. Do nothing from selfishness or conceit, but in humility count others better than yourselves. Let each of you look not only to his own interests, but also to the interests of others.",
           versicle: "All the paths of the Lord are mercy and truth;", response: "Unto such as keep his covenant and his testimonies." },
      6: { ref: "1 Kings 8:60-61", text: "That all the peoples of the earth may know that the Lord is God; there is no other, let your heart therefore be wholly true to the Lord our God, walking in his statutes and keeping his commandments, as at this day.",
           versicle: "O Lord, my God, teach me thy statutes;", response: "And show me the light of thy countenance." }
    },
    collects: [
      { title: "The Collect", text: "LORD Jesus Christ, Son of the living God, who, at the third hour of the day didst strengthen thine Apostles by the visitation of thy Holy Spirit; we humbly beseech thee, that thou wilt deign to enlighten and guard our hearts and bodies by his coming; who livest and reignest with the Father, in the unity of the same Holy Spirit, ever one God, world without end. Amen." }
    ]
  },

  sext: {
    key: "sext", latin: "Sext", name: "Midday Prayer", hour: "The Sixth Hour", defaultTime: "12:00",
    angelusNote: "At noon, the Angelus may be said before the Office, except from Easter Day until the Eve of Trinity Sunday, when the Regina Coeli is said instead.",
    opening: [
      { v: "Officiant", t: "✠ O GOD, make speed to save us." },
      { v: "People", t: "O LORD, make haste to help us." }
    ],
    hymn: {
      latin: "Rector potens, verax Deus",
      note: "Attributed to St. Ambrose. Hymnal 1940 #161, Translation by J. M. Neale.",
      verses: [
        "O GOD of truth, O Lord of might,\nwho orderest time and change aright,\nand sendest the early morning ray,\nand lightest the glow of perfect day;",
        "Extinguish thou each sinful fire,\nand banish every ill desire;\nand while thou keepest the body whole,\nshed forth thy peace upon the soul.",
        "O Father, that we ask be done,\nthrough Jesus Christ, thine only Son,\nwho, with the Holy Ghost and thee,\ndoth live and reign eternally. Amen."
      ]
    },
    psalms: [
      { num: "Psalm 123", latin: "Ad te levavi oculos meos", verses: [
        "UNTO thee lift I up mine eyes, * O thou that dwellest in the heavens.",
        "2 Behold, even as the eyes of servants look unto the hand of their masters, and as the eyes of a maiden unto the hand of her mistress, * even so our eyes wait upon the LORD our God, until he have mercy upon us.",
        "3 Have mercy upon us, O LORD, have mercy upon us; * for we are utterly despised.",
        "4 Our soul is filled with the scornful reproof of the wealthy, * and with the despitefulness of the proud."
      ]},
      { num: "Psalm 124", latin: "Nisi quia Dominus", verses: [
        "IF the LORD himself had not been on our side, now may Israel say; * if the LORD himself had not been on our side, when men rose up against us;",
        "2 They had swallowed us up alive; * when they were so wrathfully displeased at us.",
        "3 Yea, the waters had drowned us, * and the stream had gone over our soul.",
        "4 The deep waters of the proud * had gone even over our soul.",
        "5 But praised be the LORD, * who hath not given us over for a prey unto their teeth.",
        "6 Our soul is escaped even as a bird out of the snare of the fowler; * the snare is broken, and we are delivered.",
        "7 Our help standeth in the Name of the LORD, * who hath made heaven and earth."
      ]},
      { num: "Psalm 125", latin: "Qui confidunt", verses: [
        "THEY that put their trust in the LORD shall be even as the mount Sion, * which may not be removed, but standeth fast for ever.",
        "2 The hills stand about Jerusalem; * even so standeth the LORD round about his people, from this time forth for evermore.",
        "3 For the sceptre of the ungodly shall not abide upon the lot of the righteous; * lest the righteous put their hand unto wickedness.",
        "4 Do well, O LORD, * unto those that are good and true of heart.",
        "5 As for such as turn back unto their own wickedness, * the LORD shall lead them forth with the evil doers; but peace shall be upon Israel."
      ]}
    ],
    chapters: {
      0: { ref: "Galatians 6:8", text: "For he who sows to his own flesh will from the flesh reap corruption; but he who sows to the Spirit will from the Spirit reap eternal life.",
           versicle: "The Lord is gracious; his mercy is everlasting;", response: "And his truth endureth from generation to generation." },
      1: { ref: "James 1:19-20, 26", text: "Know this, my beloved brethren. Let every man be quick to hear, slow to speak, slow to anger, for the anger of man does not work the righteousness of God. If any one thinks he is religious, and does not bridle his tongue but deceives his heart, this man's religion is vain.",
           versicle: "As long as I live will I magnify thee;", response: "When my mouth praiseth thee with joyful lips." },
      2: { ref: "Proverbs 3:13-15", text: "Happy is the man who finds Wisdom, and the man who gets understanding, for the gain from it is better than gain from silver and its profit better than gold. She is more precious than jewels, and nothing you desire can compare with her.",
           versicle: "Thou, Lord, requirest truth in the inward parts;", response: "And shalt make me to understand wisdom secretly." },
      3: { ref: "1 Peter 1:15-16", text: "As he who called you is holy, be holy yourselves in all your conduct; since it is written, 'You shall be holy, for I am holy.'",
           versicle: "Let thy priests be clothed with righteousness;", response: "And let thy saints sing with joyfulness." },
      4: { ref: "Amos 5:8", text: "He who made the Pleiades and Orion, and turns deep darkness into the morning, and darkens the day into night, who calls for the waters of the sea, and pours them out upon the surface of the earth, the Lord is his Name.",
           versicle: "Glory and worship are before him;", response: "Power and honour are in his sanctuary." },
      5: { ref: "2 Corinthians 13:4", text: "For Christ was crucified in weakness, but lives by the power of God. For we are weak in him, but in dealing with you we shall live with him by the power of God.",
           versicle: "My soul cleaveth to the dust;", response: "Quicken thou me, O Lord, according to thy word." },
      6: { ref: "Jeremiah 17:9-10", text: "The heart is deceitful above all things, and desperately corrupt; who can understand it? 'I the Lord search the mind and try the heart, to give to every man according to his ways, according to the fruit of his doings.'",
           versicle: "O cleanse thou me from my secret faults;", response: "Keep thy servant also from presumptuous sins." }
    },
    collects: [
      { title: "The Collect", text: "LORD Jesus Christ, Son of the living God, who, at the sixth hour of the day, didst ascend, on Golgotha, the Cross of pain; whereon, thirsting for our salvation, thou didst permit gall and vinegar to be given thee to drink: we, thy suppliants, beseech thee, that thou wouldst kindle and inflame our hearts with the love of thy Passion, and make us continually to find our delight in thee alone, our crucified Lord; who livest and reignest with the Father and the Holy Ghost, ever one God, world without end. Amen." },
      { title: "Or", text: "BLESSED Saviour, who at this hour didst hang upon the Cross, stretching out thy loving arms: grant that all the nations of the earth may look unto thee and be saved; for thy tender mercies' sake. Amen." }
    ]
  },

  none: {
    key: "none", latin: "None", name: "Midafternoon Prayer", hour: "The Ninth Hour", defaultTime: "15:00",
    opening: [
      { v: "Officiant", t: "✠ O GOD, make speed to save us." },
      { v: "People", t: "O LORD, make haste to help us." }
    ],
    hymn: {
      latin: "Rerum Deus tenax vigor",
      note: "Attributed to St. Ambrose. Hymnal 1940 #162, Translation by J. M. Neale.",
      verses: [
        "O God, creation's secret force,\nThyself unmoved, all motion's source,\nWho from the morn till evening ray\nThrough all its changes guid'st the day",
        "Grant us, when this short life is past,\nThe glorious evening that shall last;\nThat, by a holy death attained,\nEternal glory may be gained.",
        "O Father, that we ask be done,\nthrough Jesus Christ, thine only Son,\nwho, with the Holy Ghost and thee,\ndoth live and reign eternally. Amen."
      ]
    },
    psalms: [
      { num: "Psalm 126", latin: "In convertendo", verses: [
        "WHEN the Lord turned again the captivity of Sion, * then were we like unto them that dream.",
        "2 Then was our mouth filled with laughter, * and our tongue with joy.",
        "3 Then said they among the heathen, * The Lord hath done great things for them.",
        "4 Yea, the Lord hath done great things for us already; * whereof we rejoice.",
        "5 Turn our captivity, O Lord, * as the rivers in the south.",
        "6 They that sow in tears * shall reap in joy.",
        "7 He that now goeth on his way weeping, and beareth forth good seed, * shall doubtless come again with joy, and bring his sheaves with him."
      ]},
      { num: "Psalm 127", latin: "Nisi Dominus", verses: [
        "EXCEPT the Lord build the house, * their labour is but lost that build it.",
        "2 Except the Lord keep the city, * the watchman waketh but in vain.",
        "3 It is but lost labour that ye haste to rise up early, and so late take rest, and eat the bread of carefulness; * for so he giveth his beloved sleep.",
        "4 Lo, children, and the fruit of the womb, * are an heritage and gift that cometh of the Lord.",
        "5 Like as the arrows in the hand of the giant, * even so are the young children.",
        "6 Happy is the man that hath his quiver full of them; * they shall not be ashamed when they speak with their enemies in the gate."
      ]},
      { num: "Psalm 128", latin: "Beati omnes", verses: [
        "BLESSED are all they that fear the Lord, * and walk in his ways.",
        "2 For thou shalt eat the labours of thine hands: * O well is thee, and happy shalt thou be.",
        "3 Thy wife shall be as the fruitful vine * upon the walls of thine house;",
        "4 Thy children like the olive-branches * round about thy table.",
        "5 Lo, thus shall the man be blessed * that feareth the Lord.",
        "6 The Lord from out of Sion shall so bless thee, * that thou shalt see Jerusalem in prosperity all thy life long;",
        "7 Yea, that thou shalt see thy children's children, * and peace upon Israel."
      ]}
    ],
    chapters: {
      0: { ref: "Galatians 6:9-10", text: "And let us not grow weary in well-doing, for in due season we shall reap, if we do not lose heart. So then, as we have opportunity, let us do good to all men, and especially to those who are of the household of faith.",
           versicle: "I call with my whole heart; hear me, O Lord;", response: "And I will keep thy statutes." },
      1: { ref: "1 Peter 1:17-19", text: "If you invoke as Father him who judges each one impartially according to his deeds, conduct yourselves with fear throughout the time of your exile. You know that you were ransomed from the futile ways inherited from your fathers, not with perishable things such as silver or gold, but with the precious blood of Christ, like that of a lamb without blemish or spot.",
           versicle: "Deliver me, O Lord, and be merciful unto me;", response: "And I will praise the Lord in the congregations." },
      2: { ref: "Job 5:17-18", text: "Behold, happy is the man whom God reproves; therefore despise not the chastening of the Almighty. For he wounds, but he binds up; he smites, but his hands heal.",
           versicle: "O deal with thy servant after thy loving mercy, O Lord;", response: "And teach me thy statutes." },
      3: { ref: "James 4:7-8a, 10", text: "Submit yourselves therefore to God. Resist the devil and he will flee from you. Draw near to God and he will draw near to you. Humble yourselves before the Lord and he will exalt you.",
           versicle: "The eye of the Lord is upon them that fear him;", response: "And upon them that put their trust in his mercy." },
      4: { ref: "Amos 9:6", text: "He who builds his upper chambers in the heavens, and founds his vault upon the earth; who calls for the waters of the sea, and pours them out upon the surface of the earth — the Lord is his Name.",
           versicle: "The heavens declare the glory of God;", response: "And the firmament showeth his handy-work." },
      5: { ref: "Colossians 3:12-13", text: "Put on then, as God's chosen ones, holy and beloved, compassion, kindness, lowliness, meekness, and patience, forbearing one another and, if one has a complaint against another, forgiving each other; as the Lord has forgiven you, so you also must forgive.",
           versicle: "The Lord is full of compassion and mercy;", response: "Longsuffering, and of great goodness." },
      6: { ref: "Wisdom 7:27a, 8:1", text: "Though Wisdom is but one, she can do all things, and while remaining in herself, she renews all things. She reaches mightily from one end of the earth to the other, and she orders all things well.",
           versicle: "O Lord, how glorious are thy works;", response: "And thy thoughts reach unto the depths." }
    },
    collects: [
      { title: "The Collect", text: "LORD Jesus Christ, Son of the living God, who, at the ninth hour of the day, with outstretched hands and bowed head didst commend thy spirit to God the Father, and by thy death didst unlock the gates of paradise: mercifully grant that in the hour of our death our souls may come to the true paradise, which is thyself; who livest and reignest with the Father, in the unity of the Holy Spirit, ever one God, world without end. Amen." }
    ]
  }
};

export const COLLECT_INTRO_LAY = [
  { v: "Officiant", t: "O Lord hear our prayer." },
  { v: "People", t: "And let our cry come unto thee." },
  { v: "Officiant", t: "Let us pray." }
];

export const CONCLUSION = [
  { v: "Officiant", t: "Let us bless the Lord." },
  { v: "People", t: "Thanks be to God." }
];

export const FAITHFUL_DEPARTED = "May ✠ the souls of all the faithful departed, through the mercy of God, rest in peace. Amen.";
