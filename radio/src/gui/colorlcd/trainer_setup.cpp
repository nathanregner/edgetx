/*
 * Copyright (C) EdgeTX
 *
 * Based on code named
 *   opentx - https://github.com/opentx/opentx
 *   th9x - http://code.google.com/p/th9x
 *   er9x - http://code.google.com/p/er9x
 *   gruvin9x - http://code.google.com/p/gruvin9x
 *
 * License GPLv2: http://www.gnu.org/licenses/gpl-2.0.html
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 */

#include "trainer_setup.h"
#include "opentx.h"

#define SET_DIRTY()     storageDirty(EE_MODEL)

#include "form.h"
#include "menu.h"
#include "static.h"
#include "button.h"
#include "numberedit.h"
#include "channel_range.h"
#include "ppm_settings.h"

#if defined(BLUETOOTH)
#include "trainer_bluetooth.h"
#endif

static const lv_coord_t col_dsc[] = {LV_GRID_FR(1), LV_GRID_FR(2),
                                     LV_GRID_TEMPLATE_LAST};
static const lv_coord_t row_dsc[] = {LV_GRID_CONTENT,
                                     LV_GRID_TEMPLATE_LAST};

class TrainerModuleWindow : public FormWindow
{
 public:
  TrainerModuleWindow(FormWindow* parent);

  void checkEvents() override;
  void update();

 protected:
  ChannelRange* chRange = nullptr;

#if defined(BLUETOOTH)
  // StaticText *btChannelEnd = nullptr;
  // StaticText *btDistAddress = nullptr;
  // TextButton *btMasterButton = nullptr;
  // Menu *btPopUpMenu = nullptr;
  // bool btCanceled = false;

 private:
  // bool popupopen = false;
  // int devicecount = 0;
  // uint8_t lastbluetoothstate = BLUETOOTH_STATE_OFF;

  // void btDiscoverMenuItemChosen();
  // void btDiscoverMenuAddItem(const char *itm);

#endif
};

TrainerModuleWindow::TrainerModuleWindow(FormWindow* parent) :
    FormWindow(parent, rect_t{})
{
  setFlexLayout();
  update();
}

void TrainerModuleWindow::checkEvents()
{
// #if defined(BLUETOOTH)
//   if (popupopen) {
//     if (bluetooth.state == BLUETOOTH_STATE_DISCOVER_START ||
//         bluetooth.state == BLUETOOTH_STATE_DISCOVER_END) {
//       int cnt = min<uint8_t>(reusableBuffer.moduleSetup.bt.devicesCount,
//                              MAX_BLUETOOTH_DISTANT_ADDR);
//       if (devicecount < cnt) {
//         for (int i = 0; i < cnt - devicecount; i++) {
//           int index = devicecount + i;
//           btDiscoverMenuAddItem(reusableBuffer.moduleSetup.bt.devices[index]);
//         }
//         devicecount = cnt;
//       }
//     }
//   }
//   if (bluetooth.state != lastbluetoothstate) {
//     // TODO:
//     // if (!popupopen && !trChoiceOpen) update();
//     lastbluetoothstate = bluetooth.state;
//   }
// #endif
  FormWindow::checkEvents();
}

void TrainerModuleWindow::update()
{
  FlexGridLayout grid(col_dsc, row_dsc, 2);
  clear();

  auto td = &g_model.trainerData;
  if (td->mode == TRAINER_MODE_OFF) return;

#if defined(BLUETOOTH)
  if (td->mode == TRAINER_MODE_MASTER_BLUETOOTH ||
      td->mode == TRAINER_MODE_SLAVE_BLUETOOTH) {
    
    auto bt = new BluetoothTrainerWindow(this);
    if (td->mode == TRAINER_MODE_SLAVE_BLUETOOTH)
      bt->setMaster(false);

    bt->refresh();
    // TODO: slave: channel range
  }
#endif

  if (td->mode == TRAINER_MODE_SLAVE) {

    // Channel range
    auto line = newLine(&grid);
    new StaticText(line, rect_t{}, STR_CHANNELRANGE, 0, COLOR_THEME_PRIMARY1);
    chRange = new TrainerChannelRange(line);

    // PPM frame
    line = newLine(&grid);
    new StaticText(line, rect_t{}, STR_PPMFRAME, 0, COLOR_THEME_PRIMARY1);
    new PpmFrameSettings<TrainerModuleData>(line, grid, td);
  }
}

TrainerPage::TrainerPage() : Page(ICON_MODEL_SETUP)
{
  header.setTitle(STR_MENU_MODEL_SETUP);
  header.setTitle2(STR_TRAINER);

  auto form = new FormWindow(&body, rect_t{});
  form->setFlexLayout();
  form->padAll(lv_dpx(8));

  FlexGridLayout grid(col_dsc, row_dsc, 2);

  auto line = form->newLine(&grid);
  new StaticText(line, rect_t{}, STR_MODE, 0, COLOR_THEME_PRIMARY1);

  auto trainerChoice =
      new Choice(line, rect_t{}, STR_VTRAINERMODES, 0, TRAINER_MODE_MAX(),
                 GET_SET_DEFAULT(g_model.trainerData.mode));
  trainerChoice->setAvailableHandler(isTrainerModeAvailable);

  auto trainerModule = new TrainerModuleWindow(form);

  TrainerModuleData* tr = &g_model.trainerData;
  trainerChoice->setSetValueHandler([=](int32_t newValue) {

      //TODO: move the BT stuff somewhere else?
#if defined(BLUETOOTH)
      memclear(bluetooth.distantAddr, sizeof(bluetooth.distantAddr));
      bluetooth.state = BLUETOOTH_STATE_OFF;
#endif
      tr->mode = newValue;
      trainerModule->update();
      SET_DIRTY();
    });
}
