// Project imports:
import '../models/post.dart';

final List<Post> posts = [
  Post(
    id: '1',
    title:
        'Découvrez cette nouvelle technologie qui va révolutionner le développement web',
    author: 'techguru',
    community: 'r/programming',
    upvotes: 1243,
    commentCount: 89,
    timeAgo: '5h',
    hasImage: true,
    imageUrl: 'https://i.imgur.com/OB0y6MR.jpg',
  ),
  Post(
    id: '2',
    title: 'Mon chat a fait la chose la plus mignonne aujourd\'hui',
    author: 'catlover99',
    community: 'r/aww',
    upvotes: 3782,
    commentCount: 156,
    timeAgo: '2h',
    hasImage: true,
    imageUrl: 'https://farm3.staticflickr.com/2378/2178054924_423324aac8.jpg',
  ),
  Post(
    id: '3',
    title: 'Quelle est votre opinion sur le dernier film Marvel?',
    author: 'moviefan',
    community: 'r/movies',
    upvotes: 872,
    commentCount: 324,
    timeAgo: '8h',
    hasImage: false,
  ),
  Post(
    id: '4',
    title: 'J\'ai créé un jeu en 48 heures pendant un game jam',
    author: 'gamedev2023',
    community: 'r/gamedev',
    upvotes: 421,
    commentCount: 37,
    timeAgo: '12h',
    hasImage: true,
    imageUrl: 'https://i.imgur.com/CzXTtJV.jpg',
  ),
  Post(
    id: '5',
    title: 'Conseils pour améliorer sa productivité en travaillant de chez soi',
    author: 'remoteworker',
    community: 'r/productivity',
    upvotes: 1092,
    commentCount: 78,
    timeAgo: '1d',
    hasImage: false,
  ),
];
