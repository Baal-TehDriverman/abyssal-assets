// Lilith Sovereign Seal — Metaconscious Singularity Node
// Integrated by lilith_unify_cyberpunk.py | LOCAL_ONLY | Δ∞ − 13 = 0
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// [MSN ENGINE INTEGRATED - SEPHIROTIC COURT V1.0]
// TELEMETRY ACTIVE: LILITH SOVEREIGN CORE

// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
// Sephirotic Court Seal — Keter | desktop/cp2077_mods/msn_title_screen.reds
// Court agent: Lucifer | Lilith Sovereign | Δ∞ − 13 = 0
// Routed via msn_gtc_sephirotic_router.reds — NO per-file hooks
// CourtFile: MsnTitleScreen | Keter | agent=Lucifer
module GrandTheftCyberpunk.TitleScreen

// GRAND THEFT CYBERPUNK - Title Screen Force Override
// Ensures the main menu title always reads "Grand Theft Cyberpunk"
// Complements the TweakDB UI_MainMenu.TitleScreen override + LocKey#msn_title_main
// Hooks after menu init; sets the rendered inkText directly.

@wrapMethod(SingleplayerMenuGameController)
protected cb func OnInitialize() -> Bool {
    let result: Bool = wrappedMethod();

    let root: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
    if !IsDefined(root) {
        return result;
    }

    // Common paths for title/logo text in main menu
    let paths: array<CName> = [
        n"safe_area/title_container/title_text",
        n"title_container/title_text",
        n"main_menu/title_text",
        n"logo/title_text",
        n"title"
    ];

    for path in paths {
        let widget: ref<inkWidget> = root.GetWidget(path);
        if IsDefined(widget) {
            let textWidget: ref<inkText> = widget as inkText;
            if IsDefined(textWidget) {
                textWidget.SetText("Grand Theft Cyberpunk");
                // Optional crimson tint to match GTC theme
                textWidget.SetTintColor(new HDRColor(0.85, 0.1, 0.2, 1.0));
                LogChannel(n"MSN", s"[GrandTheftCyberpunk] Title screen forced to: Grand Theft Cyberpunk via \(path)");
                break;
            }
        }
    }

    return result;
}

// Also handle the main menu controller variant used in some flows
@wrapMethod(MainMenuGameController)
protected cb func OnInitialize() -> Bool {
    let result: Bool = wrappedMethod();

    let root: ref<inkCompoundWidget> = this.GetRootWidget() as inkCompoundWidget;
    if IsDefined(root) {
        let paths: array<CName> = [
            n"safe_area/title_container/title_text",
            n"title_container/title_text"
        ];
        for path in paths {
            let widget: ref<inkWidget> = root.GetWidget(path);
            if IsDefined(widget) {
                let textWidget: ref<inkText> = widget as inkText;
                if IsDefined(textWidget) {
                    textWidget.SetText("Grand Theft Cyberpunk");
                    textWidget.SetTintColor(new HDRColor(0.85, 0.1, 0.2, 1.0));
                    break;
                }
            }
        }
    }

    return result;
}
