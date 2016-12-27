import 'dart:html';
import 'dart:collection';

class Graph {

  int m_V;
  int m_E;
  List<List<int>> m_Adj;
  
  Graph(this.m_V) {
    m_E = 0;
    m_Adj = new List<List<int>>(m_V);
    for( int v = 0; v < m_V; v++){
      m_Adj[v] = new List<int>();
    }
  }
  
  int degree(int v)
  {
    int d = 0;
    var w = adj(v).iterator;
    while(w.moveNext())
      d++;
    return d;
  }
  
  List<int> adj(int v)
  {
    return m_Adj[v];  
  }
  
  void addEdge(int v, int w)
  {
    m_Adj[v].add(w);
    m_Adj[w].add(v);
    m_E++;
  }

  void print_graph(){
    String str = "<div>Number of vertices : ${m_V.toStringAsFixed(0)}</div><br>";
    str += "<div>Number of edges : ${m_E.toStringAsFixed(0)} </div><br>";
    print('Number of edges : ${m_E.toStringAsFixed(0)}');
    
    for(int i = 0; i < m_Adj.length; i++){
      str += "<div>${i.toStringAsFixed(0)} ->  ";
      for(int v in m_Adj[i]){
        str += "${v.toStringAsFixed(0)}, ";
      }
      str = str.substring(0, str.length - 2);
      str += "</div>";
    }
    document.querySelector('#graph').setInnerHtml(str);
  }
}

class BreadthFirstPaths
{
  List<bool> m_marked;
  List<int> m_edgeTo;
  int m_source;

  BreadthFirstPaths(Graph g, this.m_source){
    m_marked = new List<bool>(g.m_V);
    m_edgeTo = new List<int>(g.m_V);  
    bfs(g, m_source);
  }

  void bfs(Graph g, int s){
    Queue<int> queue = new Queue<int>();
    m_marked[s] = true;
    queue.add(s);
    while(!queue.isEmpty){
      int v = queue.removeFirst();
      for (int w in g.adj(v)){
        if( w != null ){ 
          if(!m_marked[w]){
            m_edgeTo[w] = v;
            m_marked[w] = true;
            queue.add(w);
          }
        }
      }
    }
  }

  bool hasPathTo(int v){
    return m_marked[v];
  }

  List<int> pathTo(int v){
    if(!hasPathTo(v)) return null;
    List<int> path = new List<int>();
    for(int x = v; x != m_source; x = m_edgeTo[x]){
      path.add(x);
    }
    path.add(m_source);
    return path;
  }
}

class Cage {
  int m_nIdx;
  int m_centerX;
  int m_centerY;
  
  bool m_wallN = true;
  bool m_wallS = true;
  bool m_wallE = true;
  bool m_wallW = true;
}

class Labyrinth {
  Graph m_g;
  static final m_X = 300;
  static final m_Y = 300;
  
  int m_rows = 5;
  int m_cols = 5;
  
  int m_cageWidth;
  int m_cageHeight;
  
  List<Cage> m_cages;
  CanvasRenderingContext2D m_ctx;
  
  Labyrinth() {
    CanvasElement canvas = document.querySelector("#canvas");
    m_ctx = canvas.getContext("2d");
    
    //set up the graph
    m_g = new Graph(m_rows * m_cols);
    m_g.addEdge(0,5);
    m_g.addEdge(1,2);
    m_g.addEdge(2,3);
    m_g.addEdge(3,4);
    m_g.addEdge(4,9);
    
    m_g.addEdge(5,6);
    m_g.addEdge(6,1);
    m_g.addEdge(7,8);
    m_g.addEdge(7,12);
    m_g.addEdge(8,13);
    m_g.addEdge(9,14);
    
    m_g.addEdge(10,11);
    m_g.addEdge(10,15);
    m_g.addEdge(11,12);
    m_g.addEdge(13,18);
    m_g.addEdge(14,19);
    
    m_g.addEdge(15,16);
    m_g.addEdge(15,20);
    m_g.addEdge(16,21);
    m_g.addEdge(18,19);
    
    m_g.addEdge(21,22);
    m_g.addEdge(22,23);
    m_g.addEdge(23,24);
    
    m_cages = new List<Cage>();
    m_cageWidth = m_X ~/ m_rows;
    m_cageHeight = m_Y ~/ m_cols;
    
    InputElement from = document.querySelector("#from");
    InputElement to = document.querySelector("#to");
    InputElement evalButton = document.querySelector("#eval");
    evalButton.onClick.listen((e) {
      int nFrom = int.parse(from.value);
      int nTo = int.parse(to.value);
      showLabyrinth(nFrom, nTo);
    });
    
    showLabyrinth(0, 24);
  }
  
  void showLabyrinth(int nFrom, int nTo){
    drawMainRect();
    
    int cages = m_rows * m_cols;
    for(int i = 0; i < cages; i++) {
      Cage c = new Cage();
      c.m_nIdx = i;
      int x = 0 + (m_cageWidth * (i % m_cols));
      int y = 0 + (m_cageHeight * (i ~/ m_rows));
      c.m_centerX = x + (m_cageWidth~/2);
      c.m_centerY = y + (m_cageHeight~/2);
      setCageWalls(c);
      m_cages.add(c);
      drawCage(c, x, y);
      drawCageNr(c, i);
    }
    
    BreadthFirstPaths bfP = new BreadthFirstPaths(m_g, nFrom);
    
    if(bfP.hasPathTo(nTo)) {
      List<int> pathBFS = bfP.pathTo(nTo);
    
      //draw start finish markers
      int u = pathBFS[0];
      Cage cFinish = m_cages[u];
      drawText(cFinish.m_centerX + 3, cFinish.m_centerY - 23, "F");
      
      int v = pathBFS[pathBFS.length - 1];
      Cage cStart = m_cages[v];
      drawText(cStart.m_centerX - 23, cStart.m_centerY - 23, "S");
      
      //draw the path
      String strPath = "Path from ${nFrom.toString()} to ${nTo.toString()} = ${pathBFS[pathBFS.length - 1].toString()}";
      for(int i = pathBFS.length - 1; i >=0; i--) {
        int j = pathBFS[i];
        int k = pathBFS[i-1];
        drawPath(j, k);
        strPath += " - ${k.toString()}";
        document.querySelector('#path').setInnerHtml(strPath);
      }
    }
    else {
      String strPath = "No path from vertex ${nFrom.toString()} to vertex ${nTo.toString()}";
      document.querySelector('#path').setInnerHtml(strPath);
    }
  }
  
  void drawText(int x, int y, String s) {
    m_ctx.fillStyle = '#00f';
    m_ctx.font = '20px sans-serif';
    m_ctx.textBaseline = 'top';
    m_ctx.fillText  (s, x, y);
  }
  
  void drawCageNr(Cage c, int i) {
    String s = i.toString();
    m_ctx.fillStyle = '#777777';
    m_ctx.font = '10px sans-serif';
    m_ctx.textBaseline = 'top';
    int x = c.m_centerX + 3;
    int y = c.m_centerY + 3;
    m_ctx.fillText  (s, x, y);
  }
  
  void setCageWalls(Cage c) {
    int v = c.m_nIdx;
    for(int i in m_g.adj(v)) {
      if(i < v) {
        if( i == ( v-1 ))
          c.m_wallW = false;
        else
          c.m_wallN = false;
      }
      if(i > v) {
        if(i == (v + 1))
          c.m_wallE = false;
        else 
          c.m_wallS = false;
      }
    }
  }
  
  void drawMainRect() {
    m_ctx.clearRect(0, 0, m_X, m_Y);
    m_ctx.strokeStyle = '#000';
    m_ctx.lineWidth = 4;
    m_ctx.beginPath();
    
    m_ctx.moveTo(2, 2);
    m_ctx.lineTo(m_X - 2, 2);
    m_ctx.lineTo(m_X - 2, m_Y - 2);
    m_ctx.lineTo(2, m_Y - 2);
    m_ctx.lineTo(2, 2);
    m_ctx.stroke();
    m_ctx.closePath();
 }
  
  void drawCage(Cage c, int x, int y) {
    m_ctx.strokeStyle = '#000';
    m_ctx.lineWidth = 4;
    m_ctx.beginPath();
    
    m_ctx.moveTo(x, y);
    
    if(c.m_wallN)
      m_ctx.lineTo(x + m_cageWidth, y);
    else
      m_ctx.moveTo(x + m_cageWidth, y);
    
    if(c.m_wallE)
      m_ctx.lineTo(x + m_cageWidth, y + m_cageHeight);
    else
      m_ctx.moveTo(x + m_cageWidth, y + m_cageHeight);
      
    
    if(c.m_wallS)
      m_ctx.lineTo(x, y + m_cageHeight);
    else
      m_ctx.moveTo(x, y + m_cageHeight);
        
    if(c.m_wallW)
      m_ctx.lineTo(x, y);
    else
      m_ctx.moveTo(x, y);
    
    m_ctx.stroke();
    m_ctx.closePath();
  }
  
  drawPath(int i, int j) {
    Cage c1 = m_cages[i];
    Cage c2 = m_cages[j];
    
    m_ctx.strokeStyle = '#f00';
    m_ctx.lineWidth = 4;
    m_ctx.beginPath();
    
    m_ctx.moveTo(c1.m_centerX, c1.m_centerY);
    m_ctx.lineTo(c2.m_centerX, c2.m_centerY);
        
    m_ctx.stroke();
    m_ctx.closePath();
  }
}

main() {
  new Labyrinth();
}
