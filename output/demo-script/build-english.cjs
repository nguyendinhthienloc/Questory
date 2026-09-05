const fs = require('fs');
const {Document,Packer,Paragraph,TextRun,HeadingLevel,PageBreak,Footer,PageNumber}=require('C:/Users/Thien Loc/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/docx');
const sections=[
  {
    "title": "1 Loc",
    "meta": "0:00–2:00  |  Introduction and Tracks",
    "note": "Before recording: check the camera, prepare one saved run with quest photos and one ready-made story for later sections. Friend accounts and delivery in Tracks are simulated. Each person speaks in one continuous section.",
    "beats": [
      [
        "0:00–0:25",
        "Open Questory. Show the three tabs, then tap Tracks.",
        "Hello everyone. We are Loc, Viet, Tai, and Tuan. Questory helps people explore a city, record a run, and turn their memories into a story. We built it with Flutter and Dart for Android. I will begin with Tracks, where users can capture and browse photo moments."
      ],
      [
        "0:25–0:55",
        "In Tracks, take a photo. On Share a Track, enter a short caption. Leave all friends unselected and tap SAVE TRACK.",
        "I can take a photo and add a caption to describe the moment. With no friend selected, the button is Save Track. After saving, the photo appears as a private Track. The camera uses the phone camera through the camera package."
      ],
      [
        "0:55–1:15",
        "Swipe vertically through the saved photo and the friend posts. Tap a heart on one friend post.",
        "We can swipe through Tracks and react to a post. The friend posts shown here are bundled sample content, so we can demonstrate the feed without a server. These are demo accounts, not posts being downloaded from real users."
      ],
      [
        "1:15–1:45",
        "Return to the camera. Turn off Mock friends online. Take another photo, add a caption, select a friend, and tap SHARE TRACK. Show QUEUED OFFLINE.",
        "Selecting a friend changes the action to Share Track. In this offline demo state, the photo is marked as queued. This shows the intended sharing experience; the current friend delivery is simulated. It does not mean the photo has reached another phone."
      ],
      [
        "1:45–2:00",
        "Return to Explore.",
        "Tracks is a quick way to capture a moment. Next, Viet will show the two ways to start exploring: a route already built into the app, or Free Run."
      ]
    ]
  },
  {
    "title": "2 Viet",
    "meta": "2:00–3:40  |  Free Run and routes already built into the app",
    "note": "Show route choices only in this section. Do not take photos. Keep one prepared route ready for Tai, or show his short run as a clearly labeled separate recording.",
    "beats": [
      [
        "2:00–2:20",
        "In Explore, show Nha Trang and Ho Chi Minh City. Open one city.",
        "Questory offers two running modes. Both start from a destination. Our current city packs cover Nha Trang and Ho Chi Minh City, and their information is stored inside the app as JSON files. The city and route details can therefore load without Internet access."
      ],
      [
        "2:20–2:50",
        "Open Coastal Morning Run in Nha Trang or River and City Lights in Ho Chi Minh City. Show distance, landmarks, and the quest list.",
        "The first mode uses a route already built into the app. It provides a suggested path, an expected distance, landmarks, and photo quests. This is useful when someone is visiting a place and wants a starting plan. Users can read the details before deciding to begin."
      ],
      [
        "2:50–3:15",
        "Go back to the city screen. Tap START FREE RUN and show the discovery screen. Do not begin tracking yet.",
        "The second mode is Free Run. Users choose their own path instead of following a prepared route. They can still discover nearby places from the city pack. This suits people who already know where they want to go or want a more flexible outing."
      ],
      [
        "3:15–3:40",
        "Return to the selected built-in route and stop at START THIS ROUTE.",
        "The main difference is how the route is chosen: the built-in mode gives us a plan, while Free Run lets us make our own. Both lead to recording the activity. Tai will now show the run information, photo quests, and image sharing."
      ]
    ]
  },
  {
    "title": "3 Tai",
    "meta": "3:40–6:30  |  Run logic photo evidence and export",
    "note": "Use a short recorded run and label any time cut or simulated GPS. Use a real eligible quest, or a clearly labeled prepared recording. Prepare a finished story so this section can demonstrate export without repeating the editor tour.",
    "beats": [
      [
        "3:40–4:10",
        "Tap START THIS ROUTE → BEGIN TRACKING. Follow the permission explanation and grant location access if asked. Show a short movement clip and the tracker.",
        "The app uses geolocator to receive GPS points. Each point has a position and a time. We add the distances between accepted points to calculate the total distance. We use the Haversine formula, which measures distance between two positions on the Earth."
      ],
      [
        "4:10–4:40",
        "Point to TIME, DISTANCE, and PACE. Pause briefly, then resume. Show the example as an overlay, separate from the real app values.",
        "We filter points with poor reported accuracy or an unrealistic jump. For example, a jump above 12 meters per second is rejected. Pace is active time divided by distance in kilometers. Ten minutes over two kilometers gives five minutes per kilometer. Paused time is excluded, and pace stays unavailable when there is no valid distance."
      ],
      [
        "4:40–5:20",
        "At an eligible quest, tap CAPTURE, take a photo, enter a caption, and tap SAVE QUEST PHOTO. Finish the run and show the saved photo in Run summary.",
        "A photo quest links an image to a place. The app checks GPS quality and whether we are within the quest radius. We then take a photo and add the required caption. The saved evidence includes the photo reference, location, time, and quest. This gives the run a photo diary as well as statistics."
      ],
      [
        "5:20–5:45",
        "Show PHOTO DIARY. Then open the prepared story through its saved run and CREATE STORY. Label it “Prepared story for export”.",
        "These photos can become part of a story together with the route and run details. I will use a prepared story to show the output first. Tuan will demonstrate how to edit and save a story in the next section."
      ],
      [
        "5:45–6:30",
        "Tap EXPORT on the prepared story. Wait for the Android share sheet. Leave it open for Tuan.",
        "Export creates a portrait PNG at 1080 by 1920 pixels. Editing handles and guides are left out. Flutter renders the image, and a small Kotlin bridge opens Android sharing. We can choose an app to send the image, or an available storage option to keep a copy. Export does not automatically add it to Gallery. Tuan will continue by saving the image and showing the Journey flow."
      ]
    ],
    "formula": "Optional short overlay: distance = sum of accepted GPS segments; pace = active minutes / kilometers. Example only: 10 / 2 = 5:00 per kilometer. Keep the full Haversine equation off-screen unless the audience asks."
  },
  {
    "title": "4 Tuan",
    "meta": "6:30–9:00  |  Save on the phone Journey and Story Studio",
    "note": "Before filming, verify a storage app offered by the Android share sheet and rehearse saving a PNG. If no local save target is available, show the exported share sheet and explain the limit; do not claim the file was saved to Gallery. Use a completed run for the restart demonstration.",
    "beats": [
      [
        "6:30–6:55",
        "Continue from the open share sheet. Choose the verified local storage option, save the PNG, and open it from that app. Return to Questory.",
        "I will save a copy using the storage option available on this phone. This is the finished PNG, which we can open outside Questory. It is different from the editable project: the image is ready to use, while the project keeps the parts we can change later."
      ],
      [
        "6:55–7:25",
        "Open Journey → RUNS. Select a completed run and show its statistics, photo diary, and captions.",
        "Journey is where we return to our saved activities. Opening a run brings back its statistics and photo evidence. The app uses SQLite through sqflite to store its records. Retained photos are copied into app-controlled storage so they do not depend on temporary camera files."
      ],
      [
        "7:25–8:05",
        "Tap CREATE STORY. Show City Sprint, Film Roll, and Postcard Trail. Choose one, edit its title, move and resize a photo, then use Undo and Redo.",
        "Story Studio turns the run into a layout we can personalize. We can start with a template, change the title, move or resize a photo, and adjust the design. Undo and redo help us try changes. The project stores each part and its position, so the result remains editable."
      ],
      [
        "8:05–8:30",
        "Tap Save. Make a small unsaved change, then tap Open saved to restore the saved version. Return to Journey.",
        "Save keeps the editable project on the phone. Open saved brings back that version, including the text and layout. This lets us continue editing later without starting from the beginning."
      ],
      [
        "8:30–9:00",
        "Show the actual achievement progress. In airplane mode, close and reopen Questory, then open the completed run from Journey. Hold on the run at the end.",
        "Journey also shows personal milestones, such as a first run, three completed photo quests, and ten total kilometers. After reopening the app offline, our completed run is still here. That is the full experience: explore, record, keep the memories, and make a story. Thank you for watching."
      ]
    ]
  }
];
const kids=[];
function p(text,opts={}){return new Paragraph({...opts,children:[new TextRun({text,...(opts.run||{})})]});}
for(let i=0;i<sections.length;i++){
const s=sections[i]; if(i)kids.push(new Paragraph({children:[new PageBreak()]}));
kids.push(p('Questory demo video script',{heading:HeadingLevel.TITLE}));
kids.push(p(s.title,{heading:HeadingLevel.HEADING_1}));
kids.push(p(s.meta,{spacing:{after:110},run:{bold:true,size:21}}));
kids.push(p(s.note,{spacing:{after:140},run:{italics:true,size:20}}));
for(const [time,action,speech] of s.beats){
kids.push(p(time,{spacing:{before:100,after:35},keepNext:true,run:{bold:true,size:21}}));
kids.push(new Paragraph({spacing:{after:45},keepNext:true,children:[new TextRun({text:'Action: ',bold:true}),new TextRun(action)]}));
kids.push(new Paragraph({spacing:{after:75},children:[new TextRun({text:'Say: ',bold:true}),new TextRun('“'+speech+'”')]}));
}
if(s.formula)kids.push(p(s.formula,{spacing:{before:90},run:{italics:true,size:19}}));
}
const doc=new Document({creator:'Questory',title:'Questory demo video script bốn thành viên',description:'Four continuous sections: Loc, Viet, Tai, Tuan. Actions and speech paired. Target duration nine minutes.',styles:{default:{document:{run:{font:'Arial',size:21,color:'000000'},paragraph:{spacing:{after:65,line:250}}}},paragraphStyles:[{id:'Title',name:'Title',basedOn:'Normal',run:{font:'Arial',size:30,bold:true,color:'000000'},paragraph:{spacing:{after:90}}},{id:'Heading1',name:'heading 1',basedOn:'Normal',run:{font:'Arial',size:27,bold:true,color:'000000'},paragraph:{spacing:{after:80}}}]},sections:[{properties:{page:{size:{width:11906,height:16838},margin:{top:760,bottom:760,left:1000,right:1000}}},footers:{default:new Footer({children:[new Paragraph({children:[new TextRun({text:'Questory  |  Demo video script',size:18}),new TextRun({text:'                                         ',size:18}),new TextRun({children:[PageNumber.CURRENT],size:18})]})]})},children:kids}]});
Packer.toBuffer(doc).then(b=>{fs.writeFileSync('D:/Questory/output/demo-script/Questory_Demo_Script_English_v2.docx',b);console.log('Created DOCX');});

