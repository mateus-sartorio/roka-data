import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mobile_client/components/big_button_tile.dart';
import 'package:mobile_client/data/database.dart';
import 'package:mobile_client/modals/dialog_box.dart';
import 'package:mobile_client/models/currency_handout.dart';
import 'package:mobile_client/models/receipt.dart';
import 'package:mobile_client/models/resident.dart';
import 'package:mobile_client/utils/integer_id_generator.dart';

class CreateReceiptPage extends StatefulWidget {
  final Receipt? receipt;
  final String text;

  const CreateReceiptPage({Key? key, this.receipt, required this.text})
      : super(key: key);

  @override
  State<CreateReceiptPage> createState() => _CreateReceiptPageState();
}

class _CreateReceiptPageState extends State<CreateReceiptPage> {
  GlobalDatabase db = GlobalDatabase();

  Resident? selectedResident;
  CurrencyHandout? selectedCurrencyHandout;
  DateTime? selectedDate;
  bool isNewReceipt = true;

  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    if (widget.receipt != null) {
      selectedDate = widget.receipt?.handoutDate;
      selectedResident = db.getResidentById(widget.receipt?.residentId ?? 0);
      selectedCurrencyHandout =
          db.getCurrencyHandoutById(widget.receipt?.currencyHandoutId ?? -1);
      _valueController.text = widget.receipt?.value.toString() ?? "";
      isNewReceipt = false;
    } else {
      selectedDate = DateTime.now();
    }

    List<String> dayMonthYear =
        selectedDate.toString().split(" ")[0].split("-");
    _dateController.text =
        "${dayMonthYear[2]}/${dayMonthYear[1]}/${dayMonthYear[0]}";

    super.initState();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));

    if (picked != null) {
      setState(() {
        List<String> dayMonthYear = picked.toString().split(" ")[0].split("-");
        _dateController.text =
            "${dayMonthYear[2]}/${dayMonthYear[1]}/${dayMonthYear[0]}";
        selectedDate = picked;
      });
    }
  }

  void warnInvalidRegistrationData(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
            title: Text(
              message,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            contentPadding:
                const EdgeInsets.only(bottom: 20, left: 20, right: 20, top: 5),
            children: [
              MaterialButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "Ok",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )),
            ]);
      },
    );
  }

  bool isFormOk() {
    RegExp decimalPattern = RegExp(r'^\d+(?:[.,]\d{1,2})?$');

    if (!decimalPattern.hasMatch(_valueController.text)) {
      warnInvalidRegistrationData(
          "Valor inválido (deve ser um número decimal com no máximo duas casas decimais, separado por \".\" ou \",\")");
      return false;
    }

    return true;
  }

  void saveNewReceipt() {
    if (!isFormOk()) {
      return;
    }

    Receipt newReceipt = Receipt(
        id: widget.receipt?.id ?? generateIntegerId(),
        value: double.parse(_valueController.text.replaceAll(",", ".")),
        handoutDate: selectedDate!,
        residentId: (selectedResident?.id)!,
        currencyHandoutId: (selectedCurrencyHandout?.id)!,
        isNew: isNewReceipt);

    if (isNewReceipt) {
      db.saveNewReceipt(newReceipt);
    } else {
      db.updateReceipt(newReceipt);
    }

    Navigator.pop(context);

    showDialog(
        context: context,
        builder: (context) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            Navigator.of(context).pop(true);
          });

          return AlertDialog(
            title: const Text(
              "Entrega salva com sucesso",
              style: TextStyle(fontSize: 14),
            ),
            surfaceTintColor: Colors.transparent,
            elevation: 0.0,
            alignment: Alignment.bottomCenter,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );
        });
  }

  void deleteCollect() {
    showDialog(
      context: context,
      builder: (context) {
        return DialogBox(
          title: "Tem certeza que deseja apagar esta entrega?",
          onSave: () {
            db.deleteCollect((selectedResident?.id)!);
            Navigator.of(context).pop(true);
            Navigator.of(context).pop(true);
            showDialog(
                context: context,
                builder: (context) {
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    Navigator.of(context).pop(true);
                  });

                  return AlertDialog(
                    title: const Text(
                      "Coleta removida com sucesso",
                      style: TextStyle(fontSize: 14),
                    ),
                    surfaceTintColor: Colors.transparent,
                    elevation: 0.0,
                    alignment: Alignment.bottomCenter,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  );
                });
          },
          onCancel: () => Navigator.of(context).pop(true),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "♻️ Dados da entrega",
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back_outlined),
            ),
          )),
      body: ValueListenableBuilder(
        valueListenable: Hive.box('globalDatabase').listenable(),
        builder: (context, Box box, _) {
          final residents = box.get("RESIDENTS");
          final currencyHandouts = box.get("CURRENCY_HANDOUTS");

          List<DropdownMenuItem<Resident>> residentsDropdownList = [];
          for (dynamic r in residents) {
            residentsDropdownList.add(DropdownMenuItem<Resident>(
                value: r as Resident, child: Text(r.name)));
          }

          List<DropdownMenuItem<CurrencyHandout>> currencyHandoutsDropdownList =
              [];
          for (dynamic ch in currencyHandouts) {
            List<String> dayMonthYear =
                ch.startDate.toString().split(" ")[0].split("-");
            "${dayMonthYear[2]}/${dayMonthYear[1]}/${dayMonthYear[0]}";
            currencyHandoutsDropdownList.add(DropdownMenuItem<CurrencyHandout>(
                value: ch as CurrencyHandout,
                child: Text(
                    "${ch.title} - ${dayMonthYear[2]}/${dayMonthYear[1]}/${dayMonthYear[0]}")));
          }

          return Center(
            child: FractionallySizedBox(
              widthFactor: 0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 15),
                    child: Text(
                      widget.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 20),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Data da entrega",
                        prefix: Padding(
                          padding: EdgeInsets.only(
                              left: 0, right: 10, bottom: 0, top: 0),
                          child: Icon(
                            Icons.calendar_month,
                          ),
                        ),
                        prefixStyle: TextStyle()),
                    onTap: _selectDate,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  DropdownButtonFormField<Resident>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Residente",
                      prefix: Padding(
                        padding: EdgeInsets.only(
                            left: 0, right: 10, bottom: 0, top: 0),
                        child: Icon(
                          Icons.person,
                        ),
                      ),
                    ),
                    onChanged: (item) => selectedResident = item,
                    value: selectedResident,
                    items: residentsDropdownList,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  DropdownButtonFormField<CurrencyHandout>(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Entrega",
                      prefix: Padding(
                        padding: EdgeInsets.only(
                            left: 0, right: 10, bottom: 0, top: 0),
                        child: Icon(
                          Icons.monetization_on_rounded,
                        ),
                      ),
                    ),
                    onChanged: (item) => selectedCurrencyHandout = item,
                    value: selectedCurrencyHandout,
                    items: currencyHandoutsDropdownList,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  TextField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Valor [Rokas]",
                      border: OutlineInputBorder(),
                      labelText: "Valor [Rokas]",
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  BigButtonTile(
                      color: Colors.black,
                      content: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save, color: Colors.white),
                          Text("  Salvar localmente",
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      onPressed: saveNewReceipt,
                      isSolid: true),
                  const SizedBox(
                    height: 15,
                  ),
                  Visibility(
                    visible: !isNewReceipt,
                    child: BigButtonTile(
                        color: Colors.red,
                        content: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete, color: Colors.white),
                            Text("  Apagar",
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                        onPressed: deleteCollect,
                        isSolid: true),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
